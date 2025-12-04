#ifndef SDUIAPICLIENT_H
#define SDUIAPICLIENT_H

#include <QObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDate>

class SduiApiClient : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ isLoading NOTIFY loadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(bool authenticated READ isAuthenticated NOTIFY authenticatedChanged)
    Q_PROPERTY(QString userName READ userName NOTIFY userNameChanged)

public:
    explicit SduiApiClient(QObject *parent = nullptr);
    ~SduiApiClient();

    bool isLoading() const { return m_loading; }
    QString errorMessage() const { return m_errorMessage; }
    bool isAuthenticated() const { return m_authenticated; }
    QString userName() const { return m_userName; }

    Q_INVOKABLE void login(const QString &email, const QString &password);
    Q_INVOKABLE void loginWithToken(const QString &userId, const QString &token);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void fetchTimetable(const QDate &weekStart);
    Q_INVOKABLE void refreshToken();

signals:
    void loadingChanged();
    void errorMessageChanged();
    void authenticatedChanged();
    void userNameChanged();
    void loginSucceeded();
    void loginFailed(const QString &error);
    void timetableReceived(const QJsonObject &data);
    void timetableFailed(const QString &error);

private slots:
    void onLoginFinished(QNetworkReply *reply);
    void onTimetableFinished(QNetworkReply *reply);

private:
    void setLoading(bool loading);
    void setError(const QString &error);
    void setAuthenticated(bool auth);
    QNetworkRequest createRequest(const QString &endpoint);

    QNetworkAccessManager *m_networkManager;
    QString m_accessToken;
    QString m_userId;
    QString m_userName;
    bool m_loading = false;
    QString m_errorMessage;
    bool m_authenticated = false;

    static constexpr const char* BASE_URL = "https://api.sdui.app/v1";
    // Use web browser user agent since the web login works
    static constexpr const char* USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64; rv:133.0) Gecko/20100101 Firefox/133.0";
};

#endif // SDUIAPICLIENT_H
