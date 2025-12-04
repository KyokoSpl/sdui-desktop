import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SduiDesktop 1.0

// Day header row showing day names and dates
Rectangle {
    id: dayHeader
    
    required property TimetableModel model
    readonly property bool modelReady: model !== null
    
    height: 60
    color: "#252525"
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        // Time column spacer
        Item {
            Layout.preferredWidth: 50
        }
        
        // Day columns
        Repeater {
            model: modelReady ? dayHeader.model.daysToShow() : 0
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                property date columnDate: modelReady ? dayHeader.model.dateForDayIndex(index) : new Date()
                property bool isToday: modelReady ? dayHeader.model.isToday(columnDate) : false
                
                color: "transparent"
                
                // Left border
                Rectangle {
                    width: 1
                    height: parent.height
                    color: Qt.rgba(255, 255, 255, 0.1)
                }
                
                // Today highlight pill
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: parent.height - 12
                    radius: 12
                    color: isToday ? Qt.rgba(255/255, 107/255, 53/255, 0.2) : "transparent"
                    border.color: isToday ? "#FF6B35" : "transparent"
                    border.width: isToday ? 1 : 0
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
                
                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    // Day name
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelReady ? dayHeader.model.dayName(index) : ""
                        font.pixelSize: 11
                        font.weight: isToday ? Font.Bold : Font.Normal
                        color: isToday ? "#FF6B35" : "#888888"
                    }
                    
                    // Date number
                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: columnDate.getDate()
                        font.pixelSize: 18
                        font.weight: isToday ? Font.Bold : Font.Medium
                        color: isToday ? "#FF6B35" : "#FFFFFF"
                    }
                }
                
                // Click to switch to day view
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelReady) {
                            dayHeader.model.selectedDate = columnDate
                            dayHeader.model.viewMode = TimetableModel.Day
                        }
                    }
                }
            }
        }
    }
}
