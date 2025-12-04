#!/usr/bin/env python3
"""
SDUI API Scraper - Dynamically discovers and documents the SDUI API
Crawls responses to find new endpoints and builds a complete API map

Usage:
    python sdui_api_scraper.py --user-id YOUR_USER_ID --token YOUR_BEARER_TOKEN
"""

import argparse
import json
import re
import time
from collections import deque
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import requests


class SduiApiScraper:
    def __init__(self, user_id: str, bearer_token: str, base_url: str = "https://api.sdui.app"):
        self.user_id = user_id
        self.bearer_token = bearer_token
        self.base_url = base_url
        self.session = requests.Session()
        self.session.headers.update({
            "Authorization": f"Bearer {bearer_token}",
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0",
            "Accept": "application/json, text/plain, */*",
            "Accept-Language": "en-US,en;q=0.5",
            "Origin": "https://app.sdui.app",
            "Referer": "https://app.sdui.app/",
        })
        
        # Discovered data
        self.discovered_endpoints: dict[str, dict] = {}
        self.queue: deque[tuple[str, str, dict | None]] = deque()  # (method, url, body)
        self.visited: set[str] = set()
        
        # Rate limiting
        self.request_delay = 0.3  # seconds between requests
        self.last_request_time = 0
        
        # Context discovered from responses
        self.school_id: str | None = None
        self.school_slink: str | None = None
        
        # Date params for timetable
        today = datetime.now()
        monday = today - timedelta(days=today.weekday())
        self.date_params = {
            "begins_at": monday.strftime("%Y-%m-%d"),
            "ends_at": (monday + timedelta(days=6)).strftime("%Y-%m-%d"),
        }
    
    def normalize_url(self, url: str) -> str:
        """Normalize URL for deduplication - replace IDs with placeholders"""
        parsed = urlparse(url)
        path = parsed.path
        
        # Replace UUIDs first (they contain both letters and numbers)
        path = re.sub(r'/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}', '/{uuid}', path, flags=re.I)
        
        # Replace numeric IDs in path
        path = re.sub(r'/users/\d+', '/users/{user_id}', path)
        path = re.sub(r'/schools/\d+', '/schools/{school_id}', path)
        path = re.sub(r'/courses/\d+', '/courses/{course_id}', path)
        path = re.sub(r'/channels/\d+', '/channels/{channel_id}', path)
        path = re.sub(r'/news/\d+', '/news/{news_id}', path)
        path = re.sub(r'/events/\d+', '/events/{event_id}', path)
        path = re.sub(r'/messages/\d+', '/messages/{message_id}', path)
        path = re.sub(r'/files/\d+', '/files/{file_id}', path)
        path = re.sub(r'/surveys/\d+', '/surveys/{survey_id}', path)
        path = re.sub(r'/absences/\d+', '/absences/{absence_id}', path)
        path = re.sub(r'/timetables/\d+', '/timetables/{timetable_id}', path)
        path = re.sub(r'/lessons/\d+', '/lessons/{lesson_id}', path)
        path = re.sub(r'/bookables/\d+', '/bookables/{bookable_id}', path)
        path = re.sub(r'/teachers/\d+', '/teachers/{teacher_id}', path)
        path = re.sub(r'/subjects/\d+', '/subjects/{subject_id}', path)
        path = re.sub(r'/grades/\d+', '/grades/{grade_id}', path)
        
        # Generic fallback for other numeric IDs (4+ digits)
        path = re.sub(r'/(\d{4,})(?=/|$)', r'/{id}', path)
        
        return path
    
    def should_visit(self, url: str) -> bool:
        """Check if URL should be visited"""
        if not url.startswith(self.base_url):
            return False
        
        normalized = self.normalize_url(url)
        if normalized in self.visited:
            return False
        
        # Skip certain patterns
        skip_patterns = [
            r'/socket\.io/',
            r'/broadcast',
            r'/assets/',
            r'/static/',
            r'\.(jpg|jpeg|png|gif|svg|css|js)$',
            r'/websocket',
            r'/ws/',
        ]
        for pattern in skip_patterns:
            if re.search(pattern, url, re.I):
                return False
        
        return True
    
    def extract_urls_from_response(self, data: Any) -> set[str]:
        """Recursively extract URLs and API paths from response data"""
        urls = set()
        
        if isinstance(data, str):
            # Look for full URLs
            for match in re.finditer(r'https?://api\.sdui\.app[^\s"\'<>\]]+', data):
                url = match.group(0).rstrip('.,;:)}')
                urls.add(url)
            
            # Look for relative API paths
            for match in re.finditer(r'(/v\d+/[a-zA-Z0-9/_-]+)', data):
                urls.add(self.base_url + match.group(1))
        
        elif isinstance(data, dict):
            # Check for URL-like fields
            url_fields = ['url', 'href', 'link', 'uri', 'path', 'endpoint', 
                         'next', 'prev', 'first', 'last', 'self',
                         'next_page_url', 'prev_page_url', 'first_page_url', 'last_page_url']
            
            for key, value in data.items():
                key_lower = key.lower()
                
                # Direct URL fields
                if key_lower in url_fields and isinstance(value, str) and value:
                    if value.startswith('http'):
                        urls.add(value)
                    elif value.startswith('/v'):
                        urls.add(self.base_url + value)
                
                # Recurse into nested structures
                urls.update(self.extract_urls_from_response(value))
            
            # Check links object (common pagination pattern)
            if 'links' in data and isinstance(data['links'], dict):
                for link_val in data['links'].values():
                    if isinstance(link_val, str) and link_val:
                        if link_val.startswith('http'):
                            urls.add(link_val)
        
        elif isinstance(data, list):
            for item in data[:30]:  # Limit list traversal
                urls.update(self.extract_urls_from_response(item))
        
        return urls
    
    def extract_ids_and_generate_urls(self, data: Any) -> list[str]:
        """Extract resource IDs and generate potential endpoint URLs"""
        ids: dict[str, set[str]] = {
            'user': set(),
            'school': set(),
            'course': set(),
            'channel': set(),
            'news': set(),
            'event': set(),
            'file': set(),
        }
        
        def extract(obj: Any):
            if isinstance(obj, dict):
                # Look for ID fields
                for key, value in obj.items():
                    if isinstance(value, (int, str)) and value:
                        val_str = str(value)
                        if key == 'school_id':
                            ids['school'].add(val_str)
                            self.school_id = val_str
                        elif key == 'user_id':
                            ids['user'].add(val_str)
                        elif key == 'course_id':
                            ids['course'].add(val_str)
                        elif key == 'channel_id':
                            ids['channel'].add(val_str)
                        elif key == 'slink':
                            self.school_slink = val_str
                        elif key == 'id':
                            # Try to infer type from context
                            if 'user' in str(obj.get('type', '')).lower():
                                ids['user'].add(val_str)
                            elif 'school' in str(obj.get('type', '')).lower():
                                ids['school'].add(val_str)
                    
                    extract(value)
            
            elif isinstance(obj, list):
                for item in obj[:20]:
                    extract(item)
        
        extract(data)
        
        # Generate URLs from discovered IDs
        urls = []
        
        # User endpoints
        for uid in list(ids['user'])[:2]:
            if uid != self.user_id:  # Skip our own ID, already explored
                urls.append(f"{self.base_url}/v1/users/{uid}")
        
        # School endpoints - many endpoints need school context
        for sid in list(ids['school'])[:1]:
            base = f"{self.base_url}/v1/schools/{sid}"
            urls.extend([
                base,
                f"{base}/users",
                f"{base}/news",
                f"{base}/events",
                f"{base}/channels",
                f"{base}/courses",
                f"{base}/teachers",
                f"{base}/subjects",
                f"{base}/bookables",
                f"{base}/grades",
                f"{base}/timetable",
                f"{base}/substitutions",
                f"{base}/homework",
                f"{base}/exams",
                f"{base}/surveys",
                f"{base}/cloud",
                f"{base}/files",
                # Timetable with school context
                f"{self.base_url}/v1/timetables/schools/{sid}/timetable",
                f"{self.base_url}/v1/timetables/schools/{sid}",
                # News with school context
                f"{self.base_url}/v1/news/schools/{sid}",
                # Channels with school context
                f"{self.base_url}/v1/channels/schools/{sid}",
            ])
        
        # Course endpoints
        for cid in list(ids['course'])[:3]:
            base = f"{self.base_url}/v1/courses/{cid}"
            urls.extend([
                base,
                f"{base}/users",
                f"{base}/homework",
                f"{base}/grades",
                f"{base}/events",
                f"{base}/timetable",
            ])
        
        # Channel endpoints
        for chid in list(ids['channel'])[:3]:
            urls.extend([
                f"{self.base_url}/v1/channels/{chid}",
                f"{self.base_url}/v1/channels/{chid}/messages",
            ])
        
        return urls
    
    def rate_limit(self):
        """Apply rate limiting between requests"""
        elapsed = time.time() - self.last_request_time
        if elapsed < self.request_delay:
            time.sleep(self.request_delay - elapsed)
        self.last_request_time = time.time()
    
    def make_request(self, method: str, url: str, body: dict | None = None) -> tuple[int, Any, dict]:
        """Make an HTTP request to the API"""
        self.rate_limit()
        
        # Auto-add date params for timetable endpoints
        if 'timetable' in url and 'begins_at' not in url:
            separator = '&' if '?' in url else '?'
            url += f"{separator}begins_at={self.date_params['begins_at']}&ends_at={self.date_params['ends_at']}"
        
        try:
            if method.upper() == "GET":
                resp = self.session.get(url, timeout=30)
            elif method.upper() == "POST":
                resp = self.session.post(url, json=body, timeout=30)
            elif method.upper() == "PUT":
                resp = self.session.put(url, json=body, timeout=30)
            elif method.upper() == "DELETE":
                resp = self.session.delete(url, timeout=30)
            elif method.upper() == "PATCH":
                resp = self.session.patch(url, json=body, timeout=30)
            else:
                return 0, None, {}
            
            try:
                data = resp.json()
            except json.JSONDecodeError:
                data = {"_raw": resp.text[:2000]} if resp.text else None
            
            return resp.status_code, data, dict(resp.headers)
        
        except requests.RequestException as e:
            return 0, {"_error": str(e)}, {}
    
    def infer_schema(self, data: Any, depth: int = 0, max_depth: int = 6) -> dict:
        """Infer JSON schema from response data"""
        if depth > max_depth:
            return {"type": "object", "_truncated": True}
        
        if data is None:
            return {"type": "null"}
        elif isinstance(data, bool):
            return {"type": "boolean", "example": data}
        elif isinstance(data, int):
            return {"type": "integer", "example": data}
        elif isinstance(data, float):
            return {"type": "number", "example": data}
        elif isinstance(data, str):
            schema: dict[str, Any] = {"type": "string"}
            if len(data) < 100:
                schema["example"] = data
            if re.match(r'^\d{4}-\d{2}-\d{2}', data):
                schema["format"] = "date-time"
            elif re.match(r'^[a-f0-9-]{36}$', data, re.I):
                schema["format"] = "uuid"
            elif re.match(r'^https?://', data):
                schema["format"] = "uri"
            return schema
        elif isinstance(data, list):
            if not data:
                return {"type": "array", "items": {}}
            return {
                "type": "array",
                "items": self.infer_schema(data[0], depth + 1, max_depth),
                "_count": len(data)
            }
        elif isinstance(data, dict):
            props = {}
            for key, value in list(data.items())[:25]:
                if not key.startswith('_'):
                    props[key] = self.infer_schema(value, depth + 1, max_depth)
            return {"type": "object", "properties": props}
        
        return {"type": "string"}
    
    def explore(self, method: str, url: str, body: dict | None = None) -> dict | None:
        """Explore a single endpoint and document it"""
        normalized = self.normalize_url(url)
        
        if normalized in self.visited:
            return None
        
        self.visited.add(normalized)
        
        # Truncate URL for display
        display_url = url[:70] + "..." if len(url) > 70 else url
        print(f"  [{method}] {display_url}", end=" ", flush=True)
        
        status, response, headers = self.make_request(method, url, body)
        
        if status == 0:
            print("ERROR")
            return None
        
        print(f"-> {status}")
        
        # Skip error responses for discovery (but still document them)
        if status >= 400:
            return {
                "method": method,
                "url": url,
                "path": normalized,
                "status": status,
                "error": True,
            }
        
        # Extract and queue new URLs from response
        found_urls = self.extract_urls_from_response(response)
        for new_url in found_urls:
            if self.should_visit(new_url):
                self.queue.append(("GET", new_url, None))
        
        # Generate URLs from IDs found in response
        generated = self.extract_ids_and_generate_urls(response)
        for gen_url in generated:
            if self.should_visit(gen_url):
                self.queue.append(("GET", gen_url, None))
        
        return {
            "method": method,
            "url": url,
            "path": normalized,
            "status": status,
            "content_type": headers.get("content-type", "application/json"),
            "response": response,
            "schema": self.infer_schema(response),
        }
    
    def run(self, max_requests: int = 100) -> dict:
        """Run the crawler to discover API endpoints"""
        print("\n" + "=" * 70)
        print("SDUI API Dynamic Scraper")
        print("=" * 70)
        print(f"User ID: {self.user_id}")
        print(f"Base URL: {self.base_url}")
        print(f"Max requests: {max_requests}")
        print("=" * 70 + "\n")
        
        # Seed with known endpoint patterns - includes various resource base paths
        # The SDUI API uses different patterns like:
        #   /v1/users/{id}/...
        #   /v1/timetables/users/{id}/...
        #   /v1/channels/{id}/...
        #   etc.
        seeds = [
            # User info endpoints
            f"{self.base_url}/v1/users/self",
            f"{self.base_url}/v1/users/{self.user_id}",
            f"{self.base_url}/v1/users/{self.user_id}/family",
            f"{self.base_url}/v1/users/{self.user_id}/settings",
            
            # Timetable endpoints (note the /timetables/ base path!)
            f"{self.base_url}/v1/timetables/users/{self.user_id}/timetable",
            f"{self.base_url}/v1/timetables/users/{self.user_id}",
            
            # News & feeds
            f"{self.base_url}/v1/users/{self.user_id}/feed",
            f"{self.base_url}/v1/users/{self.user_id}/news",
            f"{self.base_url}/v1/news",
            f"{self.base_url}/v1/news?page=1",
            
            # Channels & messaging
            f"{self.base_url}/v1/users/{self.user_id}/channels",
            f"{self.base_url}/v1/channels",
            f"{self.base_url}/v1/channels/users/{self.user_id}",
            
            # Cloud/files
            f"{self.base_url}/v1/users/{self.user_id}/files",
            f"{self.base_url}/v1/users/{self.user_id}/cloud",
            f"{self.base_url}/v1/cloud",
            f"{self.base_url}/v1/cloud/users/{self.user_id}",
            
            # Courses & education
            f"{self.base_url}/v1/users/{self.user_id}/courses",
            f"{self.base_url}/v1/courses",
            f"{self.base_url}/v1/courses/users/{self.user_id}",
            
            # Events
            f"{self.base_url}/v1/users/{self.user_id}/events",
            f"{self.base_url}/v1/events",
            f"{self.base_url}/v1/events/users/{self.user_id}",
            
            # Surveys
            f"{self.base_url}/v1/users/{self.user_id}/surveys",
            f"{self.base_url}/v1/surveys",
            f"{self.base_url}/v1/surveys/users/{self.user_id}",
            
            # Notifications
            f"{self.base_url}/v1/users/{self.user_id}/notifications",
            f"{self.base_url}/v1/notifications",
            f"{self.base_url}/v1/notifications/users/{self.user_id}",
            
            # Absences
            f"{self.base_url}/v1/users/{self.user_id}/absences",
            f"{self.base_url}/v1/absences",
            f"{self.base_url}/v1/absences/users/{self.user_id}",
            
            # Schools
            f"{self.base_url}/v1/schools",
            f"{self.base_url}/v1/schools/users/{self.user_id}",
            
            # Homework/tasks
            f"{self.base_url}/v1/users/{self.user_id}/homework",
            f"{self.base_url}/v1/homework",
            f"{self.base_url}/v1/homework/users/{self.user_id}",
            f"{self.base_url}/v1/users/{self.user_id}/tasks",
            f"{self.base_url}/v1/tasks",
            
            # Grades
            f"{self.base_url}/v1/users/{self.user_id}/grades",
            f"{self.base_url}/v1/grades",
            f"{self.base_url}/v1/grades/users/{self.user_id}",
            
            # Exams
            f"{self.base_url}/v1/users/{self.user_id}/exams",
            f"{self.base_url}/v1/exams",
            f"{self.base_url}/v1/exams/users/{self.user_id}",
            
            # Bookables (rooms etc)
            f"{self.base_url}/v1/bookables",
            
            # Teachers
            f"{self.base_url}/v1/teachers",
            
            # Subjects
            f"{self.base_url}/v1/subjects",
            
            # Substitutions/replacements
            f"{self.base_url}/v1/substitutions",
            f"{self.base_url}/v1/substitutions/users/{self.user_id}",
            f"{self.base_url}/v1/users/{self.user_id}/substitutions",
        ]
        
        for url in seeds:
            self.queue.append(("GET", url, None))
        
        count = 0
        print("Crawling...\n")
        
        while self.queue and count < max_requests:
            method, url, body = self.queue.popleft()
            
            if not self.should_visit(url):
                continue
            
            doc = self.explore(method, url, body)
            if doc and not doc.get("error"):
                self.discovered_endpoints[doc["path"]] = doc
            
            count += 1
            
            if count % 10 == 0:
                print(f"\n  [{count}/{max_requests}] Found {len(self.discovered_endpoints)} endpoints, {len(self.queue)} queued\n")
        
        print(f"\n{'=' * 70}")
        print(f"Complete! Made {count} requests, discovered {len(self.discovered_endpoints)} endpoints")
        print(f"{'=' * 70}\n")
        
        return self.discovered_endpoints
    
    def to_openapi(self) -> dict:
        """Generate OpenAPI 3.0 specification"""
        paths: dict[str, dict] = {}
        
        for path, doc in self.discovered_endpoints.items():
            if path not in paths:
                paths[path] = {}
            
            method = doc.get("method", "get").lower()
            
            # Build parameters list
            params = []
            
            # Path parameters
            for match in re.finditer(r'\{(\w+)\}', path):
                params.append({
                    "name": match.group(1),
                    "in": "path",
                    "required": True,
                    "schema": {"type": "string"}
                })
            
            # Query parameters from URL
            if '?' in doc.get("url", ""):
                query = doc["url"].split("?")[1]
                for pair in query.split("&"):
                    if "=" in pair:
                        name = pair.split("=")[0]
                        if not any(p["name"] == name for p in params):
                            params.append({
                                "name": name,
                                "in": "query",
                                "schema": {"type": "string"}
                            })
            
            # Determine tag from path
            parts = path.split("/")
            tag = parts[2] if len(parts) > 2 else "api"
            
            operation = {
                "summary": f"{method.upper()} {path}",
                "tags": [tag],
                "security": [{"bearerAuth": []}],
                "responses": {
                    str(doc.get("status", 200)): {
                        "description": "Response",
                        "content": {
                            "application/json": {
                                "schema": doc.get("schema", {})
                            }
                        }
                    }
                }
            }
            
            if params:
                operation["parameters"] = params
            
            paths[path][method] = operation
        
        return {
            "openapi": "3.0.3",
            "info": {
                "title": "SDUI API",
                "description": "Auto-discovered SDUI API documentation",
                "version": "1.0.0",
            },
            "servers": [{"url": self.base_url}],
            "components": {
                "securitySchemes": {
                    "bearerAuth": {
                        "type": "http",
                        "scheme": "bearer",
                        "bearerFormat": "JWT"
                    }
                }
            },
            "paths": paths
        }
    
    def save(self, output_dir: Path):
        """Save results to files"""
        output_dir.mkdir(parents=True, exist_ok=True)
        
        # Full raw data
        with open(output_dir / "sdui_api_raw.json", "w") as f:
            json.dump(self.discovered_endpoints, f, indent=2, default=str)
        
        # OpenAPI spec
        with open(output_dir / "sdui_openapi.json", "w") as f:
            json.dump(self.to_openapi(), f, indent=2)
        
        # Simple endpoint list
        endpoints = [
            {"method": d["method"], "path": p, "status": d["status"]}
            for p, d in sorted(self.discovered_endpoints.items())
        ]
        with open(output_dir / "sdui_endpoints.json", "w") as f:
            json.dump(endpoints, f, indent=2)
        
        # Markdown summary
        with open(output_dir / "README.md", "w") as f:
            f.write("# SDUI API Documentation\n\n")
            f.write(f"Auto-generated on {datetime.now().isoformat()}\n\n")
            f.write(f"**Endpoints discovered:** {len(self.discovered_endpoints)}\n\n")
            f.write("## Endpoints\n\n")
            f.write("| Method | Path | Status |\n")
            f.write("|--------|------|--------|\n")
            for p, d in sorted(self.discovered_endpoints.items()):
                f.write(f"| {d['method']} | `{p}` | {d['status']} |\n")
        
        print(f"Saved to {output_dir}/:")
        print("  - sdui_api_raw.json (full responses)")
        print("  - sdui_openapi.json (OpenAPI 3.0 spec)")
        print("  - sdui_endpoints.json (endpoint list)")
        print("  - README.md (summary)")


def main():
    parser = argparse.ArgumentParser(description="SDUI API Scraper")
    parser.add_argument("-u", "--user-id", required=True, help="Your SDUI user ID")
    parser.add_argument("-t", "--token", required=True, help="Bearer token (without 'Bearer ' prefix)")
    parser.add_argument("-o", "--output", default="./sdui_api_docs", help="Output directory")
    parser.add_argument("-m", "--max-requests", type=int, default=100, help="Maximum requests to make")
    
    args = parser.parse_args()
    
    # Clean token
    token = args.token.strip()
    if token.lower().startswith("bearer "):
        token = token[7:]
    
    scraper = SduiApiScraper(args.user_id, token)
    scraper.run(args.max_requests)
    scraper.save(Path(args.output))


if __name__ == "__main__":
    main()
