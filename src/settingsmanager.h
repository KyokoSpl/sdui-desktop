#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>
#include <QSettings>

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)
    Q_PROPERTY(int viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(QString accessToken READ accessToken WRITE setAccessToken NOTIFY accessTokenChanged)
    Q_PROPERTY(QString userId READ userId WRITE setUserId NOTIFY userIdChanged)
    Q_PROPERTY(QString userName READ userName WRITE setUserName NOTIFY userNameChanged)

public:
    static SettingsManager* instance();
    
    // Theme
    bool darkMode() const;
    void setDarkMode(bool dark);
    
    // View settings
    int viewMode() const;
    void setViewMode(int mode);
    
    // Auth
    QString accessToken() const;
    void setAccessToken(const QString &token);
    
    QString userId() const;
    void setUserId(const QString &id);
    
    QString userName() const;
    void setUserName(const QString &name);

signals:
    void darkModeChanged();
    void viewModeChanged();
    void accessTokenChanged();
    void userIdChanged();
    void userNameChanged();

private:
    explicit SettingsManager(QObject *parent = nullptr);
    static SettingsManager* s_instance;
    QSettings m_settings;
};

#endif // SETTINGSMANAGER_H
