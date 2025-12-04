import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SduiDesktop 1.0
import "components"

Page {
    id: settingsPage
    
    required property SduiApiClient apiClient
    
    signal back()
    signal logout()
    
    background: Rectangle {
        color: "#1A1A1A"
    }
    
    header: ToolBar {
        Material.background: "#252525"
        height: 64
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 16
            
            RoundButton {
                icon.source: "qrc:/icons/arrow-left.svg"
                icon.width: 24
                icon.height: 24
                flat: true
                onClicked: back()
            }
            
            Label {
                text: "Settings"
                font.pixelSize: 20
                font.weight: Font.Medium
            }
            
            Item { Layout.fillWidth: true }
        }
    }
    
    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        
        ColumnLayout {
            width: parent.width
            spacing: 0
            
            // Account section
            SettingsSection {
                title: "Account"
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    // User info
                    Rectangle {
                        Layout.fillWidth: true
                        height: 72
                        color: "transparent"
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 16
                            
                            // Avatar
                            Rectangle {
                                width: 48
                                height: 48
                                radius: 24
                                color: "#FF6B35"
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: Settings.userName.length > 0 ? Settings.userName.charAt(0).toUpperCase() : "?"
                                    font.pixelSize: 20
                                    font.bold: true
                                    color: "white"
                                }
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                
                                Label {
                                    text: Settings.userName || "Unknown User"
                                    font.pixelSize: 16
                                    font.weight: Font.Medium
                                }
                                
                                Label {
                                    text: "User ID: " + Settings.userId
                                    font.pixelSize: 12
                                    color: "#AAAAAA"
                                }
                            }
                        }
                    }
                    
                    // Logout button
                    ItemDelegate {
                        Layout.fillWidth: true
                        
                        contentItem: RowLayout {
                            spacing: 16
                            
                            Rectangle {
                                width: 24
                                height: 24
                                color: "transparent"
                                
                                Label {
                                    anchors.centerIn: parent
                                    text: "🚪"
                                    font.pixelSize: 16
                                }
                            }
                            
                            Label {
                                text: "Sign Out"
                                color: "#FF6B6B"
                                font.pixelSize: 14
                            }
                            
                            Item { Layout.fillWidth: true }
                        }
                        
                        onClicked: logoutDialog.open()
                    }
                }
            }
            
            // Appearance section
            SettingsSection {
                title: "Appearance"
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    // View mode
                    ItemDelegate {
                        Layout.fillWidth: true
                        
                        contentItem: RowLayout {
                            spacing: 16
                            
                            Label {
                                text: "🗓️"
                                font.pixelSize: 16
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Label {
                                    text: "Default View"
                                    font.pixelSize: 14
                                }
                                
                                Label {
                                    text: ["Day", "Work Week", "Full Week"][Settings.viewMode]
                                    font.pixelSize: 12
                                    color: "#AAAAAA"
                                }
                            }
                            
                            ComboBox {
                                model: ["Day", "Work Week", "Full Week"]
                                currentIndex: Settings.viewMode
                                onCurrentIndexChanged: Settings.viewMode = currentIndex
                            }
                        }
                    }
                }
            }
            
            // About section
            SettingsSection {
                title: "About"
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    
                    ItemDelegate {
                        Layout.fillWidth: true
                        enabled: false
                        
                        contentItem: RowLayout {
                            spacing: 16
                            
                            Label {
                                text: "ℹ️"
                                font.pixelSize: 16
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Label {
                                    text: "Version"
                                    font.pixelSize: 14
                                }
                                
                                Label {
                                    text: "1.0.0"
                                    font.pixelSize: 12
                                    color: "#AAAAAA"
                                }
                            }
                        }
                    }
                    
                    ItemDelegate {
                        Layout.fillWidth: true
                        enabled: false
                        
                        contentItem: RowLayout {
                            spacing: 16
                            
                            Label {
                                text: "⚡"
                                font.pixelSize: 16
                            }
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                
                                Label {
                                    text: "Built with"
                                    font.pixelSize: 14
                                }
                                
                                Label {
                                    text: "Qt 6 / QML"
                                    font.pixelSize: 12
                                    color: "#AAAAAA"
                                }
                            }
                        }
                    }
                }
            }
            
            // Spacer
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 40
            }
        }
    }
    
    // Logout confirmation dialog
    Dialog {
        id: logoutDialog
        anchors.centerIn: parent
        title: "Sign Out"
        standardButtons: Dialog.Cancel | Dialog.Ok
        modal: true
        
        Label {
            text: "Are you sure you want to sign out?"
            wrapMode: Text.WordWrap
        }
        
        onAccepted: logout()
    }
}
