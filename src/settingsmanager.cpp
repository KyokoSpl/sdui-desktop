#include "settingsmanager.h"

SettingsManager* SettingsManager::s_instance = nullptr;

SettingsManager* SettingsManager::instance()
{
    if (!s_instance) {
        s_instance = new SettingsManager();
    }
    return s_instance;
}

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
    , m_settings("VanilleTee", "SduiDesktop")
{
}

bool SettingsManager::darkMode() const
{
    return m_settings.value("theme/darkMode", true).toBool();
}

void SettingsManager::setDarkMode(bool dark)
{
    if (darkMode() != dark) {
        m_settings.setValue("theme/darkMode", dark);
        emit darkModeChanged();
    }
}

int SettingsManager::viewMode() const
{
    return m_settings.value("view/viewMode", 1).toInt(); // Default to WorkWeek
}

void SettingsManager::setViewMode(int mode)
{
    if (viewMode() != mode) {
        m_settings.setValue("view/viewMode", mode);
        emit viewModeChanged();
    }
}

QString SettingsManager::accessToken() const
{
    return m_settings.value("auth/accessToken", "").toString();
}

void SettingsManager::setAccessToken(const QString &token)
{
    if (accessToken() != token) {
        m_settings.setValue("auth/accessToken", token);
        emit accessTokenChanged();
    }
}

QString SettingsManager::userId() const
{
    return m_settings.value("auth/userId", "").toString();
}

void SettingsManager::setUserId(const QString &id)
{
    if (userId() != id) {
        m_settings.setValue("auth/userId", id);
        emit userIdChanged();
    }
}

QString SettingsManager::userName() const
{
    return m_settings.value("auth/userName", "").toString();
}

void SettingsManager::setUserName(const QString &name)
{
    if (userName() != name) {
        m_settings.setValue("auth/userName", name);
        emit userNameChanged();
    }
}
