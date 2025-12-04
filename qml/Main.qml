import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SduiDesktop 1.0

ApplicationWindow {
    id: root
    width: 1200
    height: 800
    minimumWidth: 400
    minimumHeight: 600
    visible: true
    title: "SDUI Desktop"
    
    // Material Dark Theme with SDUI Orange accent
    Material.theme: Material.Dark
    Material.accent: "#FF6B35"
    Material.primary: "#FF6B35"
    Material.background: "#1A1A1A"
    Material.foreground: "#ECECEC"
    
    // Custom colors
    readonly property color sduiOrange: "#FF6B35"
    readonly property color sduiTeal: "#00B4A0"
    readonly property color sduiPurple: "#7C4DFF"
    readonly property color surfaceColor: "#252525"
    readonly property color surfaceVariant: "#2D2D2D"
    readonly property color cardColor: "#1E1E1E"
    
    // API Client
    SduiApiClient {
        id: sduiApiClient
        
        onLoginSucceeded: {
            stackView.push(timetablePage)
            timetableModel.goToToday()
            sduiApiClient.fetchTimetable(timetableModel.weekStart)
        }
        
        onLoginFailed: function(error) {
            loginErrorDialog.text = error
            loginErrorDialog.open()
        }
        
        onTimetableReceived: function(data) {
            timetableModel.loadFromJson(data)
        }
        
        onTimetableFailed: function(error) {
            errorSnackbar.text = error
            errorSnackbar.open()
        }
    }
    
    // Timetable Model
    TimetableModel {
        id: timetableModel
        
        onWeekStartChanged: {
            if (sduiApiClient.authenticated) {
                sduiApiClient.fetchTimetable(weekStart)
            }
        }
    }
    
    // Error dialog for login
    Dialog {
        id: loginErrorDialog
        property alias text: errorLabel.text
        
        anchors.centerIn: parent
        title: "Login Failed"
        standardButtons: Dialog.Ok
        modal: true
        
        Label {
            id: errorLabel
            wrapMode: Text.WordWrap
            width: parent.width
        }
    }
    
    // Snackbar for errors
    Popup {
        id: errorSnackbar
        property alias text: snackbarLabel.text
        
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: parent.height - height - 20
        width: Math.min(400, parent.width - 40)
        height: 48
        
        background: Rectangle {
            color: "#323232"
            radius: 4
        }
        
        contentItem: RowLayout {
            Label {
                id: snackbarLabel
                Layout.fillWidth: true
                color: "white"
            }
            Button {
                text: "Dismiss"
                flat: true
                onClicked: errorSnackbar.close()
            }
        }
        
        onOpened: closeTimer.start()
        
        Timer {
            id: closeTimer
            interval: 5000
            onTriggered: errorSnackbar.close()
        }
    }
    
    // Main content
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: sduiApiClient.authenticated ? timetablePage : loginPage
    }
    
    Component {
        id: loginPage
        LoginPage {
            apiClient: sduiApiClient
        }
    }
    
    Component {
        id: timetablePage
        TimetablePage {
            apiClient: sduiApiClient
            timetableModel: timetableModel
            onLogout: {
                sduiApiClient.logout()
                stackView.pop()
                stackView.push(loginPage)
            }
            onOpenSettings: {
                stackView.push(settingsPage)
            }
        }
    }
    
    Component {
        id: settingsPage
        SettingsPage {
            apiClient: sduiApiClient
            onBack: stackView.pop()
            onLogout: {
                sduiApiClient.logout()
                stackView.clear()
                stackView.push(loginPage)
            }
        }
    }
}
