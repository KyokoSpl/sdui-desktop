#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>
#include <QIcon>

#include "sduiapiclient.h"
#include "timetablemodel.h"
#include "settingsmanager.h"
#include "logger.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Set application metadata
    app.setApplicationName("SDUI Desktop");
    app.setOrganizationName("VanilleTee");
    app.setOrganizationDomain("vanilletee.com");
    app.setApplicationVersion("1.0.0");
    
    // Initialize logger early
    Logger* logger = Logger::instance();
    LOG_UI("Application starting");
    LOG_UI(QString("Version: %1").arg(app.applicationVersion()));
    LOG_API("Logger initialized - API logging enabled");
    
    // Force Material Dark theme
    QQuickStyle::setStyle("Material");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_THEME", "Dark");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Dense");
    
    // Register C++ types with QML
    qmlRegisterType<SduiApiClient>("SduiDesktop", 1, 0, "SduiApiClient");
    qmlRegisterType<TimetableModel>("SduiDesktop", 1, 0, "TimetableModel");
    qmlRegisterType<LessonItem>("SduiDesktop", 1, 0, "LessonItem");
    qmlRegisterSingletonType<SettingsManager>("SduiDesktop", 1, 0, "Settings", 
        [](QQmlEngine *engine, QJSEngine *scriptEngine) -> QObject* {
            Q_UNUSED(engine)
            Q_UNUSED(scriptEngine)
            return SettingsManager::instance();
        });
    
    QQmlApplicationEngine engine;
    
    // Expose logger paths to QML
    engine.rootContext()->setContextProperty("apiLogPath", logger->apiLogPath());
    engine.rootContext()->setContextProperty("uiLogPath", logger->uiLogPath());
    
    LOG_UI("QML engine created, loading Main.qml");
    
    // Load main QML file
    const QUrl url(QStringLiteral("qrc:/qt/qml/SduiDesktop/qml/Main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);
    
    return app.exec();
}
