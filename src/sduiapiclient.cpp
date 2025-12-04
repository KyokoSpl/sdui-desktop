#include "sduiapiclient.h"
#include "settingsmanager.h"
#include "logger.h"
#include <QUrlQuery>
#include <QNetworkRequest>

SduiApiClient::SduiApiClient(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
    // Try to restore session from settings
    auto settings = SettingsManager::instance();
    m_accessToken = settings->accessToken();
    m_userId = settings->userId();
    m_userName = settings->userName();
    
    if (!m_accessToken.isEmpty() && !m_userId.isEmpty()) {
        m_authenticated = true;
        emit authenticatedChanged();
        emit userNameChanged();
    }
}

SduiApiClient::~SduiApiClient()
{
}

void SduiApiClient::setLoading(bool loading)
{
    if (m_loading != loading) {
        m_loading = loading;
        emit loadingChanged();
    }
}

void SduiApiClient::setError(const QString &error)
{
    m_errorMessage = error;
    emit errorMessageChanged();
}

void SduiApiClient::setAuthenticated(bool auth)
{
    if (m_authenticated != auth) {
        m_authenticated = auth;
        emit authenticatedChanged();
    }
}

QNetworkRequest SduiApiClient::createRequest(const QString &endpoint)
{
    QNetworkRequest request(QUrl(QString(BASE_URL) + endpoint));
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json; charset=utf-8");
    request.setRawHeader("User-Agent", USER_AGENT);
    request.setRawHeader("Accept", "application/json, text/plain, */*");
    request.setRawHeader("Accept-Language", "en-US,en;q=0.5");
    request.setRawHeader("Origin", "https://app.sdui.app");
    request.setRawHeader("Referer", "https://app.sdui.app/");
    
    if (!m_accessToken.isEmpty()) {
        QString authHeader = QString("Bearer %1").arg(m_accessToken);
        request.setRawHeader("Authorization", authHeader.toUtf8());
        LOG_API(QString("Auth header length: %1").arg(authHeader.length()));
        LOG_API(QString("Auth header start: %1...").arg(authHeader.left(70)));
        LOG_API(QString("Auth header end: ...%1").arg(authHeader.right(30)));
    } else {
        LOG_API("WARNING: No access token set for request!");
    }
    
    return request;
}

void SduiApiClient::login(const QString &email, const QString &password)
{
    setLoading(true);
    setError("");
    
    QJsonObject loginData;
    loginData["identifier"] = email;
    loginData["password"] = password;
    
    // Correct endpoint: /v1/auth/login (not /users/auth/login)
    QNetworkRequest request = createRequest("/auth/login");
    QByteArray body = QJsonDocument(loginData).toJson();
    
    // Log the request
    LOG_REQUEST("POST", request.url().toString(), body);
    
    QNetworkReply *reply = m_networkManager->post(request, body);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onLoginFinished(reply);
    });
}

void SduiApiClient::loginWithToken(const QString &userId, const QString &token)
{
    setLoading(true);
    setError("");
    
    // Directly set credentials - clean up input
    m_userId = userId.trimmed();
    
    // Strip "Bearer " prefix if user accidentally included it, and remove any whitespace/newlines
    QString cleanToken = token.trimmed();
    cleanToken.remove('\n');
    cleanToken.remove('\r');
    cleanToken.remove(' ');  // Remove any spaces in the token
    
    if (cleanToken.startsWith("Bearer", Qt::CaseInsensitive)) {
        cleanToken = cleanToken.mid(6); // Remove "Bearer" (6 chars, space already removed)
    }
    m_accessToken = cleanToken;
    m_userName = "User " + m_userId;
    
    // Log token info for debugging
    LOG_API(QString("Token login - User ID: %1").arg(m_userId));
    LOG_API(QString("Token (first 50 chars): %1...").arg(m_accessToken.left(50)));
    LOG_API(QString("Token (last 20 chars): ...%1").arg(m_accessToken.right(20)));
    LOG_API(QString("Token length: %1").arg(m_accessToken.length()));
    
    // Save to settings
    auto settings = SettingsManager::instance();
    settings->setAccessToken(m_accessToken);
    settings->setUserId(m_userId);
    settings->setUserName(m_userName);
    
    setAuthenticated(true);
    setLoading(false);
    emit userNameChanged();
    emit loginSucceeded();
}

void SduiApiClient::onLoginFinished(QNetworkReply *reply)
{
    setLoading(false);
    
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QByteArray data = reply->readAll();
    QString url = reply->url().toString();
    
    if (reply->error() != QNetworkReply::NoError) {
        QString error = reply->errorString();
        
        // Log the error response
        LOG_RESPONSE(statusCode, url, data, error);
        
        // Try to parse error response
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (doc.isObject()) {
            QJsonObject obj = doc.object();
            if (obj.contains("message")) {
                error = obj["message"].toString();
            } else if (obj.contains("error")) {
                error = obj["error"].toString();
            }
        }
        
        reply->deleteLater();
        setError(error);
        emit loginFailed(error);
        return;
    }
    
    // Log successful response
    LOG_RESPONSE(statusCode, url, data, "");
    
    reply->deleteLater();
    
    QJsonDocument doc = QJsonDocument::fromJson(data);
    
    if (!doc.isObject()) {
        setError("Invalid response from server");
        emit loginFailed("Invalid response from server");
        return;
    }
    
    QJsonObject response = doc.object();
    QJsonObject dataObj = response["data"].toObject();
    
    // Extract tokens and user info - try multiple possible field names
    m_accessToken = dataObj["accesstoken"].toString();
    if (m_accessToken.isEmpty()) {
        m_accessToken = dataObj["access_token"].toString();
    }
    if (m_accessToken.isEmpty()) {
        m_accessToken = response["access_token"].toString();
    }
    if (m_accessToken.isEmpty()) {
        m_accessToken = response["token"].toString();
    }
    
    // Try to get user info from different possible locations
    QJsonObject user = dataObj["user"].toObject();
    if (user.isEmpty()) {
        user = response["user"].toObject();
    }
    
    if (user["id"].isDouble()) {
        m_userId = QString::number(user["id"].toInt());
    } else {
        m_userId = user["id"].toString();
    }
    
    QString firstName = user["firstname"].toString();
    QString lastName = user["lastname"].toString();
    m_userName = firstName + " " + lastName;
    
    if (m_accessToken.isEmpty() || m_userId.isEmpty()) {
        setError("Login failed: missing credentials in response");
        emit loginFailed("Login failed: missing credentials in response");
        return;
    }
    
    // Save to settings
    auto settings = SettingsManager::instance();
    settings->setAccessToken(m_accessToken);
    settings->setUserId(m_userId);
    settings->setUserName(m_userName);
    
    setAuthenticated(true);
    emit userNameChanged();
    emit loginSucceeded();
}

void SduiApiClient::logout()
{
    m_accessToken.clear();
    m_userId.clear();
    m_userName.clear();
    
    auto settings = SettingsManager::instance();
    settings->setAccessToken("");
    settings->setUserId("");
    settings->setUserName("");
    
    setAuthenticated(false);
    emit userNameChanged();
}

void SduiApiClient::fetchTimetable(const QDate &weekStart)
{
    if (!m_authenticated) {
        LOG_API("fetchTimetable called but not authenticated");
        emit timetableFailed("Not authenticated");
        return;
    }
    
    setLoading(true);
    setError("");
    
    QDate weekEnd = weekStart.addDays(6);
    
    // Use begins_at and ends_at like the Android app does
    QString endpoint = QString("/timetables/users/%1/timetable?begins_at=%2&ends_at=%3")
        .arg(m_userId)
        .arg(weekStart.toString("yyyy-MM-dd"))
        .arg(weekEnd.toString("yyyy-MM-dd"));
    
    QNetworkRequest request = createRequest(endpoint);
    
    // Log the request
    LOG_REQUEST("GET", request.url().toString(), QByteArray());
    
    QNetworkReply *reply = m_networkManager->get(request);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        onTimetableFinished(reply);
    });
}

void SduiApiClient::onTimetableFinished(QNetworkReply *reply)
{
    setLoading(false);
    
    int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QByteArray data = reply->readAll();
    QString url = reply->url().toString();
    
    if (reply->error() != QNetworkReply::NoError) {
        QString error = reply->errorString();
        
        // Log the error
        LOG_RESPONSE(statusCode, url, data, error);
        
        if (reply->error() == QNetworkReply::AuthenticationRequiredError) {
            logout();
            error = "Session expired. Please login again.";
        }
        
        reply->deleteLater();
        setError(error);
        emit timetableFailed(error);
        return;
    }
    
    // Log successful response
    LOG_RESPONSE(statusCode, url, data, "");
    
    reply->deleteLater();
    
    QJsonDocument doc = QJsonDocument::fromJson(data);
    
    if (!doc.isObject()) {
        setError("Invalid timetable response");
        emit timetableFailed("Invalid timetable response");
        return;
    }
    
    QJsonObject response = doc.object();
    emit timetableReceived(response);
}

void SduiApiClient::refreshToken()
{
    // Implement token refresh if needed
}
