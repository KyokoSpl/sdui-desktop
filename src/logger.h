#ifndef LOGGER_H
#define LOGGER_H

#include <QObject>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>
#include <QMutex>

class Logger : public QObject
{
    Q_OBJECT

public:
    enum LogType {
        API,
        UI
    };
    Q_ENUM(LogType)

    static Logger* instance();
    
    void log(LogType type, const QString &message);
    void logApi(const QString &message);
    void logUi(const QString &message);
    
    // For request/response logging
    void logRequest(const QString &method, const QString &url, const QByteArray &body = QByteArray());
    void logResponse(int statusCode, const QString &url, const QByteArray &body, const QString &error = QString());
    
    QString apiLogPath() const { return m_apiLogPath; }
    QString uiLogPath() const { return m_uiLogPath; }

private:
    explicit Logger(QObject *parent = nullptr);
    ~Logger();
    
    void initLogFiles();
    void writeToFile(const QString &filePath, const QString &message);
    QString formatTimestamp() const;
    
    static Logger *s_instance;
    QString m_apiLogPath;
    QString m_uiLogPath;
    QMutex m_mutex;
};

// Convenience macros
#define LOG_API(msg) Logger::instance()->logApi(msg)
#define LOG_UI(msg) Logger::instance()->logUi(msg)
#define LOG_REQUEST(method, url, body) Logger::instance()->logRequest(method, url, body)
#define LOG_RESPONSE(status, url, body, error) Logger::instance()->logResponse(status, url, body, error)

#endif // LOGGER_H
