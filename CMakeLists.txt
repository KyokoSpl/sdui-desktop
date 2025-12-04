cmake_minimum_required(VERSION 3.16)

project(SduiDesktop VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Find Qt6
find_package(Qt6 REQUIRED COMPONENTS 
    Core 
    Gui 
    Quick 
    QuickControls2 
    Network
)

qt_standard_project_setup(REQUIRES 6.5)

# Add executable
qt_add_executable(sdui-desktop
    src/main.cpp
    src/sduiapiclient.cpp
    src/sduiapiclient.h
    src/timetablemodel.cpp
    src/timetablemodel.h
    src/settingsmanager.cpp
    src/settingsmanager.h
    src/logger.cpp
    src/logger.h
)

# Add QML module
qt_add_qml_module(sdui-desktop
    URI SduiDesktop
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/LoginPage.qml
        qml/TimetablePage.qml
        qml/SettingsPage.qml
        qml/components/GlassCard.qml
        qml/components/LessonCard.qml
        qml/components/FloatingControls.qml
        qml/components/DayHeader.qml
        qml/components/TimeColumn.qml
        qml/components/SettingsSection.qml
    RESOURCES
        resources/icons/icons.qrc
)

target_link_libraries(sdui-desktop PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Network
)

# Install
install(TARGETS sdui-desktop
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
