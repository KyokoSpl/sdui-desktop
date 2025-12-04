import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SduiDesktop 1.0

Page {
    id: loginPage
    
    required property SduiApiClient apiClient
    
    property int loginMethod: 0  // 0 = email/password, 1 = token
    
    background: Rectangle {
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1A1A1A" }
            GradientStop { position: 0.5; color: "#252525" }
            GradientStop { position: 1.0; color: "#1A1A1A" }
        }
    }
    
    // Animated background circles
    Item {
        anchors.fill: parent
        
        Rectangle {
            id: circle1
            width: 400
            height: 400
            radius: 200
            color: Qt.rgba(255/255, 107/255, 53/255, 0.1)
            x: -100
            y: -100
            
            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: 50; duration: 8000; easing.type: Easing.InOutSine }
                NumberAnimation { to: -100; duration: 8000; easing.type: Easing.InOutSine }
            }
        }
        
        Rectangle {
            id: circle2
            width: 300
            height: 300
            radius: 150
            color: Qt.rgba(0, 180/255, 160/255, 0.08)
            x: parent.width - 200
            y: parent.height > 0 ? parent.height - 200 : 0
            
            SequentialAnimation on y {
                loops: Animation.Infinite
                running: circle2.parent && circle2.parent.height > 0
                NumberAnimation { to: circle2.parent ? circle2.parent.height - 250 : 0; duration: 6000; easing.type: Easing.InOutSine }
                NumberAnimation { to: circle2.parent ? circle2.parent.height - 200 : 0; duration: 6000; easing.type: Easing.InOutSine }
            }
        }
    }
    
    // Content
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 24
        width: Math.min(400, parent.width - 48)
        
        // Logo and title
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            
            // App icon
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 72
                height: 72
                radius: 18
                color: "#FF6B35"
                
                Label {
                    anchors.centerIn: parent
                    text: "S"
                    font.pixelSize: 42
                    font.bold: true
                    color: "white"
                }
            }
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "SDUI Desktop"
                font.pixelSize: 28
                font.bold: true
                color: "#FFFFFF"
            }
        }
        
        // Login card
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: loginColumn.height + 40
            radius: 16
            color: Qt.rgba(30/255, 30/255, 30/255, 0.95)
            border.color: Qt.rgba(255, 255, 255, 0.1)
            border.width: 1
            
            ColumnLayout {
                id: loginColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 20
                }
                spacing: 16
                
                // Login method tabs
                Row {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    Rectangle {
                        width: parent.width / 2
                        height: 36
                        radius: 8
                        color: loginMethod === 0 ? "#FF6B35" : "transparent"
                        
                        Label {
                            anchors.centerIn: parent
                            text: "Email Login"
                            font.pixelSize: 13
                            font.weight: loginMethod === 0 ? Font.Bold : Font.Normal
                            color: loginMethod === 0 ? "white" : "#888888"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: loginMethod = 0
                        }
                    }
                    
                    Rectangle {
                        width: parent.width / 2
                        height: 36
                        radius: 8
                        color: loginMethod === 1 ? "#FF6B35" : "transparent"
                        
                        Label {
                            anchors.centerIn: parent
                            text: "Token Login"
                            font.pixelSize: 13
                            font.weight: loginMethod === 1 ? Font.Bold : Font.Normal
                            color: loginMethod === 1 ? "white" : "#888888"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: loginMethod = 1
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#404040"
                }
                
                // Email/Password fields (method 0)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    visible: loginMethod === 0
                    
                    // Email field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Label {
                            text: "Email"
                            font.pixelSize: 13
                            color: "#AAAAAA"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 8
                            color: "#2A2A2A"
                            border.color: emailField.activeFocus ? "#FF6B35" : "#3A3A3A"
                            border.width: emailField.activeFocus ? 2 : 1
                            
                            TextInput {
                                id: emailField
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                selectByMouse: true
                                clip: true
                                
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "your.email@example.com"
                                    color: "#555555"
                                    font.pixelSize: 14
                                    visible: !emailField.text && !emailField.activeFocus
                                }
                            }
                        }
                    }
                    
                    // Password field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Label {
                            text: "Password"
                            font.pixelSize: 13
                            color: "#AAAAAA"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 8
                            color: "#2A2A2A"
                            border.color: passwordField.activeFocus ? "#FF6B35" : "#3A3A3A"
                            border.width: passwordField.activeFocus ? 2 : 1
                            
                            TextInput {
                                id: passwordField
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                echoMode: TextInput.Password
                                selectByMouse: true
                                clip: true
                                
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Enter your password"
                                    color: "#555555"
                                    font.pixelSize: 14
                                    visible: !passwordField.text && !passwordField.activeFocus
                                }
                                
                                Keys.onReturnPressed: doLogin()
                            }
                        }
                    }
                }
                
                // Token fields (method 1)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    visible: loginMethod === 1
                    
                    // User ID field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Label {
                            text: "User ID"
                            font.pixelSize: 13
                            color: "#AAAAAA"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 8
                            color: "#2A2A2A"
                            border.color: userIdField.activeFocus ? "#FF6B35" : "#3A3A3A"
                            border.width: userIdField.activeFocus ? 2 : 1
                            
                            TextInput {
                                id: userIdField
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                selectByMouse: true
                                clip: true
                                
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "e.g. 123456"
                                    color: "#555555"
                                    font.pixelSize: 14
                                    visible: !userIdField.text && !userIdField.activeFocus
                                }
                            }
                        }
                    }
                    
                    // Bearer Token field
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        
                        Label {
                            text: "Bearer Token"
                            font.pixelSize: 13
                            color: "#AAAAAA"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: 8
                            color: "#2A2A2A"
                            border.color: tokenField.activeFocus ? "#FF6B35" : "#3A3A3A"
                            border.width: tokenField.activeFocus ? 2 : 1
                            
                            TextInput {
                                id: tokenField
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                color: "#FFFFFF"
                                font.pixelSize: 14
                                echoMode: TextInput.Password
                                selectByMouse: true
                                clip: true
                                
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Paste your bearer token"
                                    color: "#555555"
                                    font.pixelSize: 14
                                    visible: !tokenField.text && !tokenField.activeFocus
                                }
                                
                                Keys.onReturnPressed: doLogin()
                            }
                        }
                    }
                    
                    // Help text for token method
                    Label {
                        Layout.fillWidth: true
                        text: "Find these in browser DevTools (F12) → Network → login request"
                        font.pixelSize: 11
                        color: "#666666"
                        wrapMode: Text.WordWrap
                    }
                }
                
                // Login button
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    Layout.topMargin: 4
                    radius: 8
                    color: canLogin ? (loginMouseArea.pressed ? "#E55A2B" : "#FF6B35") : "#3D3D3D"
                    
                    property bool canLogin: {
                        if (apiClient && apiClient.loading) return false
                        if (loginMethod === 0) {
                            return emailField.text.length > 0 && passwordField.text.length > 0
                        } else {
                            return userIdField.text.length > 0 && tokenField.text.length > 0
                        }
                    }
                    
                    Label {
                        anchors.centerIn: parent
                        text: "Sign In"
                        font.pixelSize: 15
                        font.weight: Font.Medium
                        color: parent.canLogin ? "white" : "#666666"
                        visible: !apiClient || !apiClient.loading
                    }
                    
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: apiClient && apiClient.loading
                        visible: apiClient && apiClient.loading
                        width: 24
                        height: 24
                    }
                    
                    MouseArea {
                        id: loginMouseArea
                        anchors.fill: parent
                        enabled: parent.canLogin
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: doLogin()
                    }
                    
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
        
        // Footer
        Label {
            Layout.alignment: Qt.AlignHCenter
            text: "Unofficial SDUI client"
            font.pixelSize: 12
            color: "#555555"
        }
    }
    
    function doLogin() {
        if (!apiClient) return
        
        if (loginMethod === 0) {
            apiClient.login(emailField.text, passwordField.text)
        } else {
            apiClient.loginWithToken(userIdField.text, tokenField.text)
        }
    }
}
