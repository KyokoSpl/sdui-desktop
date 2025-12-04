import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SduiDesktop 1.0
import "components"

Page {
    id: timetablePage
    
    required property SduiApiClient apiClient
    required property TimetableModel timetableModel
    
    // Helper to safely access timetableModel properties
    readonly property bool modelReady: timetableModel !== null
    readonly property int currentViewMode: modelReady ? timetableModel.viewMode : TimetableModel.WorkWeek
    readonly property date currentWeekStart: modelReady ? timetableModel.weekStart : new Date()
    readonly property date currentSelectedDate: modelReady ? timetableModel.selectedDate : new Date()
    readonly property int currentLessonCount: modelReady ? timetableModel.lessonCount : 0
    readonly property var currentHourSlots: modelReady ? timetableModel.hourSlots : []
    
    signal logout()
    signal openSettings()
    
    background: Rectangle {
        color: "#1A1A1A"
    }
    
    // Header
    header: ToolBar {
        Material.background: "#252525"
        height: 64
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            
            // Week navigation
            RowLayout {
                spacing: 8
                
                RoundButton {
                    icon.source: "qrc:/icons/chevron-left.svg"
                    icon.width: 24
                    icon.height: 24
                    flat: true
                    enabled: modelReady
                    onClicked: {
                        if (!modelReady) return
                        if (timetableModel.viewMode === TimetableModel.Day) {
                            timetableModel.previousDay()
                        } else {
                            timetableModel.previousWeek()
                        }
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: currentViewMode === TimetableModel.Day ? "Previous day" : "Previous week"
                }
                
                Label {
                    id: dateLabel
                    text: {
                        if (!modelReady) return ""
                        if (currentViewMode === TimetableModel.Day) {
                            return Qt.formatDate(currentSelectedDate, "ddd, d MMM yyyy")
                        } else {
                            let start = currentWeekStart
                            let daysToAdd = currentViewMode === TimetableModel.WorkWeek ? 4 : 6
                            let end = new Date(start)
                            end.setDate(end.getDate() + daysToAdd)
                            return Qt.formatDate(start, "d MMM") + " - " + Qt.formatDate(end, "d MMM yyyy")
                        }
                    }
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: "#FFFFFF"
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (modelReady) timetableModel.goToToday()
                    }
                }
                
                RoundButton {
                    icon.source: "qrc:/icons/chevron-right.svg"
                    icon.width: 24
                    icon.height: 24
                    flat: true
                    enabled: modelReady
                    onClicked: {
                        if (!modelReady) return
                        if (timetableModel.viewMode === TimetableModel.Day) {
                            timetableModel.nextDay()
                        } else {
                            timetableModel.nextWeek()
                        }
                    }
                    
                    ToolTip.visible: hovered
                    ToolTip.text: currentViewMode === TimetableModel.Day ? "Next day" : "Next week"
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // View mode selector
            RowLayout {
                spacing: 4
                
                Repeater {
                    model: [
                        { text: "Day", mode: TimetableModel.Day },
                        { text: "Work Week", mode: TimetableModel.WorkWeek },
                        { text: "Full Week", mode: TimetableModel.FullWeek }
                    ]
                    
                    Button {
                        text: modelData.text
                        flat: true
                        checkable: true
                        checked: currentViewMode === modelData.mode
                        enabled: modelReady
                        
                        background: Rectangle {
                            radius: 8
                            color: checked ? "#FF6B35" : (hovered ? "#3D3D3D" : "transparent")
                            
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }
                        
                        onClicked: if (modelReady) timetableModel.viewMode = modelData.mode
                    }
                }
            }
            
            Item { Layout.preferredWidth: 16 }
            
            // Action buttons
            RowLayout {
                spacing: 4
                
                RoundButton {
                    icon.source: "qrc:/icons/today.svg"
                    icon.width: 20
                    icon.height: 20
                    flat: true
                    enabled: modelReady
                    onClicked: if (modelReady) timetableModel.goToToday()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Go to today"
                }
                
                RoundButton {
                    icon.source: "qrc:/icons/refresh.svg"
                    icon.width: 20
                    icon.height: 20
                    flat: true
                    enabled: !apiClient.loading && modelReady
                    onClicked: if (modelReady) apiClient.fetchTimetable(timetableModel.weekStart)
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Refresh"
                    
                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1000
                        running: apiClient.loading
                        loops: Animation.Infinite
                    }
                }
                
                RoundButton {
                    icon.source: "qrc:/icons/settings.svg"
                    icon.width: 20
                    icon.height: 20
                    flat: true
                    onClicked: openSettings()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: "Settings"
                }
            }
        }
    }
    
    // Main content
    Item {
        anchors.fill: parent
        
        // Loading overlay
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(26/255, 26/255, 26/255, 0.8)
            visible: apiClient.loading && currentLessonCount === 0
            z: 100
            
            BusyIndicator {
                anchors.centerIn: parent
                running: parent.visible
            }
        }
        
        // Empty state
        ColumnLayout {
            anchors.centerIn: parent
            visible: !apiClient.loading && currentLessonCount === 0
            spacing: 16
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "📅"
                font.pixelSize: 64
            }
            
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: "No lessons this week"
                font.pixelSize: 18
                color: "#AAAAAA"
            }
            
            Button {
                Layout.alignment: Qt.AlignHCenter
                text: "Refresh"
                enabled: modelReady
                onClicked: if (modelReady) apiClient.fetchTimetable(timetableModel.weekStart)
            }
        }
        
        // Timetable grid
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0
            visible: currentLessonCount > 0
            
            // Day headers
            DayHeader {
                Layout.fillWidth: true
                model: timetableModel
            }
            
            // Scrollable content
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                RowLayout {
                    width: parent.width
                    spacing: 0
                    
                    // Time column
                    TimeColumn {
                        Layout.preferredWidth: 50
                        Layout.fillHeight: true
                        hourSlots: currentHourSlots
                    }
                    
                    // Day columns
                    Repeater {
                        model: modelReady ? timetableModel.daysToShow() : 0
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            
                            property date columnDate: modelReady ? timetableModel.dateForDayIndex(index) : new Date()
                            property bool isToday: modelReady ? timetableModel.isToday(columnDate) : false
                            
                            // Today highlight
                            Rectangle {
                                anchors.fill: parent
                                color: isToday ? Qt.rgba(255/255, 107/255, 53/255, 0.05) : "transparent"
                            }
                            
                            // Left border
                            Rectangle {
                                width: 1
                                height: parent.height
                                color: Qt.rgba(255, 255, 255, 0.1)
                            }
                            
                            // Lessons for this day
                            Column {
                                anchors.fill: parent
                                anchors.margins: 2
                                spacing: 4
                                
                                Repeater {
                                    model: currentHourSlots
                                    
                                    Item {
                                        width: parent.width
                                        height: 70
                                        
                                        property string hourNumber: modelData
                                        property var lessons: modelReady ? timetableModel.lessonsForHour(columnDate, hourNumber) : []
                                        
                                        // Empty slot background
                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.margins: 1
                                            radius: 8
                                            color: Qt.rgba(255, 255, 255, 0.03)
                                            visible: lessons.length === 0
                                        }
                                        
                                        // Lessons
                                        Row {
                                            anchors.fill: parent
                                            spacing: 2
                                            
                                            Repeater {
                                                model: lessons
                                                
                                                LessonCard {
                                                    width: (parent.width - (lessons.length - 1) * 2) / lessons.length
                                                    height: parent.height
                                                    lesson: modelData
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
