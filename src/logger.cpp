#include "logger.h"
#include <QDebug>
#include <QJsonDocument>

Logger* Logger::s_instance = nullptr;

Logger* Logger::instance()
{
    if (!s_instance) {
        s_instance = new Logger();
    }
    return s_instance;
}

Logger::Logger(QObject *parent)
    : QObject(parent)
{
    initLogFiles();
}

Logger::~Logger()
{
}

void Logger::initLogFiles()
{
    // Use app data location for logs
    QString logDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation) + "/logs";
    QDir().mkpath(logDir);
    
    m_apiLogPath = logDir + "/api.log";
    m_uiLogPath = logDir + "/ui.log";
    
    // Clear old logs on startup (or append - your choice)
    QFile apiFile(m_apiLogPath);
    if (apiFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        QTextStream stream(&apiFile);
        stream << "=== SDUI Desktop API Log ===" << Qt::endl;
        stream << "Started: " << formatTimestamp() << Qt::endl;
        stream << "Log file: " << m_apiLogPath << Qt::endl;
        stream << QString("=").repeated(60) << Qt::endl << Qt::endl;
        apiFile.close();
    }
    
    QFile uiFile(m_uiLogPath);
    if (uiFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        QTextStream stream(&uiFile);
        stream << "=== SDUI Desktop UI Log ===" << Qt::endl;
        stream << "Started: " << formatTimestamp() << Qt::endl;
        stream << "Log file: " << m_uiLogPath << Qt::endl;
        stream << QString("=").repeated(60) << Qt::endl << Qt::endl;
        uiFile.close();
    }
    
    qDebug() << "Logger initialized";
    qDebug() << "API log:" << m_apiLogPath;
    qDebug() << "UI log:" << m_uiLogPath;
}

QString Logger::formatTimestamp() const
{
    return QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss.zzz");
}

void Logger::writeToFile(const QString &filePath, const QString &message)
{
    QMutexLocker locker(&m_mutex);
    
    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Append)) {
        QTextStream stream(&file);
        stream << message << Qt::endl;
        file.close();
    }
    
    // Also output to console for debugging
    qDebug().noquote() << message;
}

void Logger::log(LogType type, const QString &message)
{
    QString timestamp = formatTimestamp();
    QString formattedMsg = QString("[%1] %2").arg(timestamp, message);
    
    QString filePath = (type == API) ? m_apiLogPath : m_uiLogPath;
    writeToFile(filePath, formattedMsg);
}

void Logger::logApi(const QString &message)
{
    log(API, message);
}

void Logger::logUi(const QString &message)
{
    log(UI, message);
}

void Logger::logRequest(const QString &method, const QString &url, const QByteArray &body)
{
    QString msg = QString("\n>>> REQUEST: %1 %2").arg(method, url);
    if (!body.isEmpty()) {
        // Pretty print JSON if possible
        QJsonDocument doc = QJsonDocument::fromJson(body);
        if (!doc.isNull()) {
            msg += QString("\nBody:\n%1").arg(QString(doc.toJson(QJsonDocument::Indented)));
        } else {
            msg += QString("\nBody: %1").arg(QString(body));
        }
    }
    msg += "\n" + QString("-").repeated(60);
    logApi(msg);
}

void Logger::logResponse(int statusCode, const QString &url, const QByteArray &body, const QString &error)
{
    QString msg = QString("\n<<< RESPONSE: %1 from %2").arg(statusCode).arg(url);
    
    if (!error.isEmpty()) {
        msg += QString("\nError: %1").arg(error);
    }
    
    if (!body.isEmpty()) {
        // Pretty print JSON if possible, but truncate very long responses
        QJsonDocument doc = QJsonDocument::fromJson(body);
        QString bodyStr;
        if (!doc.isNull()) {
            bodyStr = QString(doc.toJson(QJsonDocument::Indented));
        } else {
            bodyStr = QString(body);
        }
        
        // Truncate if too long (keep first 5000 chars)
        if (bodyStr.length() > 5000) {
            bodyStr = bodyStr.left(5000) + "\n... [TRUNCATED]";
        }
        msg += QString("\nBody:\n%1").arg(bodyStr);
    }
    
    msg += "\n" + QString("=").repeated(60);
    logApi(msg);
}
