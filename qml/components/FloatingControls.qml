import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SduiDesktop 1.0

// Floating action controls overlay (inspired by Android FloatingControls)
Item {
    id: floatingControls
    
    property var apiClient
    property var timetableModel
    
    signal settingsClicked()
    
    anchors {
        top: parent.top
        left: parent.left
        right: parent.right
        margins: 16
    }
    height: 120
    
    // Glass background
    Rectangle {
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(30/255, 30/255, 30/255, 0.9)
        border.color: Qt.rgba(255, 255, 255, 0.1)
        border.width: 1
        
        // Blur effect simulation with gradient
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(255, 255, 255, 0.05) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.1) }
            }
        }
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        
        // Top row: Navigation and actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            // Previous button
            RoundButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                flat: true
                
                background: Rectangle {
                    radius: 20
                    color: parent.pressed ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                }
                
                contentItem: Label {
                    text: "<"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (timetableModel.viewMode === TimetableModel.Day) {
                        timetableModel.previousDay()
                    } else {
                        timetableModel.previousWeek()
                    }
                }
            }
            
            // Date display
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: formatDateRange()
                font.pixelSize: 16
                font.weight: Font.Medium
                
                function formatDateRange() {
                    if (timetableModel.viewMode === TimetableModel.Day) {
                        return Qt.formatDate(timetableModel.selectedDate, "dddd, d MMMM")
                    } else {
                        var start = timetableModel.weekStart
                        var days = timetableModel.viewMode === TimetableModel.WorkWeek ? 4 : 6
                        var end = new Date(start)
                        end.setDate(end.getDate() + days)
                        return Qt.formatDate(start, "d MMM") + " – " + Qt.formatDate(end, "d MMM")
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: timetableModel.goToToday()
                }
            }
            
            // Next button
            RoundButton {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                flat: true
                
                background: Rectangle {
                    radius: 20
                    color: parent.pressed ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                }
                
                contentItem: Label {
                    text: ">"
                    font.pixelSize: 20
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                
                onClicked: {
                    if (timetableModel.viewMode === TimetableModel.Day) {
                        timetableModel.nextDay()
                    } else {
                        timetableModel.nextWeek()
                    }
                }
            }
        }
        
        // Bottom row: View mode and quick actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            // View mode selector (segmented control)
            Row {
                spacing: 0
                
                Repeater {
                    model: [
                        { text: "Day", mode: TimetableModel.Day },
                        { text: "5 Days", mode: TimetableModel.WorkWeek },
                        { text: "Week", mode: TimetableModel.FullWeek }
                    ]
                    
                    Rectangle {
                        width: 60
                        height: 32
                        color: timetableModel.viewMode === modelData.mode ? "#FF6B35" : Qt.rgba(255, 255, 255, 0.1)
                        radius: index === 0 ? 8 : (index === 2 ? 8 : 0)
                        
                        // Handle corner radius for segmented look
                        Rectangle {
                            visible: index === 0
                            anchors.right: parent.right
                            width: parent.width / 2
                            height: parent.height
                            color: parent.color
                        }
                        Rectangle {
                            visible: index === 2
                            anchors.left: parent.left
                            width: parent.width / 2
                            height: parent.height
                            color: parent.color
                        }
                        
                        Label {
                            anchors.centerIn: parent
                            text: modelData.text
                            font.pixelSize: 12
                            font.weight: timetableModel.viewMode === modelData.mode ? Font.Bold : Font.Normal
                            color: timetableModel.viewMode === modelData.mode ? "white" : "#AAAAAA"
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: timetableModel.viewMode = modelData.mode
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Quick action buttons
            RowLayout {
                spacing: 4
                
                // Today button
                RoundButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    flat: true
                    
                    background: Rectangle {
                        radius: 18
                        color: parent.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                    }
                    
                    contentItem: Label {
                        text: "📅"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Today"
                    
                    onClicked: timetableModel.goToToday()
                }
                
                // Refresh button
                RoundButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    flat: true
                    enabled: !apiClient.loading
                    
                    background: Rectangle {
                        radius: 18
                        color: parent.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                    }
                    
                    contentItem: Label {
                        text: "🔄"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        opacity: apiClient.loading ? 0.5 : 1.0
                        
                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            running: apiClient.loading
                            loops: Animation.Infinite
                        }
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Refresh"
                    
                    onClicked: apiClient.fetchTimetable(timetableModel.weekStart)
                }
                
                // Settings button
                RoundButton {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    flat: true
                    
                    background: Rectangle {
                        radius: 18
                        color: parent.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                    }
                    
                    contentItem: Label {
                        text: "⚙️"
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Settings"
                    
                    onClicked: settingsClicked()
                }
            }
        }
    }
}
