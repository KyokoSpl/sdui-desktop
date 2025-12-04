import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SduiDesktop 1.0

Rectangle {
    id: lessonCard
    
    property var lesson: null
    
    radius: 8
    color: lesson ? Qt.rgba(lesson.lessonColor.r, lesson.lessonColor.g, lesson.lessonColor.b, 0.2) : "transparent"
    border.color: lesson ? Qt.rgba(lesson.lessonColor.r, lesson.lessonColor.g, lesson.lessonColor.b, 0.5) : "transparent"
    border.width: 1
    
    // Status-based styling
    opacity: lesson && lesson.status === 1 ? 0.5 : 1.0 // Cancelled = dim
    
    // Left accent bar
    Rectangle {
        width: 4
        height: parent.height
        radius: 2
        color: lesson ? lesson.lessonColor : "#FF6B35"
        anchors.left: parent.left
    }
    
    // Content
    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 6
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        spacing: 2
        
        // Subject
        Label {
            Layout.fillWidth: true
            text: lesson ? lesson.subject : ""
            font.pixelSize: 12
            font.weight: Font.Bold
            color: lesson && lesson.status === 1 ? "#888888" : "#FFFFFF"
            elide: Text.ElideRight
            
            // Strike-through for cancelled
            font.strikeout: lesson && lesson.status === 1
        }
        
        // Teacher
        Label {
            Layout.fillWidth: true
            text: lesson ? lesson.teacher : ""
            font.pixelSize: 10
            color: "#AAAAAA"
            elide: Text.ElideRight
            visible: text.length > 0
        }
        
        Item { Layout.fillHeight: true }
        
        // Room and status row
        RowLayout {
            Layout.fillWidth: true
            spacing: 4
            
            // Room badge
            Rectangle {
                visible: lesson && lesson.room.length > 0
                Layout.preferredHeight: 16
                Layout.preferredWidth: roomLabel.width + 8
                radius: 4
                color: Qt.rgba(255, 255, 255, 0.1)
                
                Label {
                    id: roomLabel
                    anchors.centerIn: parent
                    text: lesson ? lesson.room : ""
                    font.pixelSize: 9
                    color: "#CCCCCC"
                }
            }
            
            Item { Layout.fillWidth: true }
            
            // Status indicator
            Rectangle {
                visible: lesson && lesson.status !== 0
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: {
                    if (!lesson) return "transparent"
                    switch (lesson.status) {
                        case 1: return "#FF6B6B" // Cancelled
                        case 2: return "#FFD93D" // Substitution
                        case 3: return "#00B4A0" // Room changed
                        case 4: return "#7C4DFF" // Teacher changed
                        default: return "transparent"
                    }
                }
            }
        }
    }
    
    // Hover effect
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            if (lesson) {
                lessonPopup.open()
            }
        }
    }
    
    // Hover glow
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: lesson ? Qt.rgba(lesson.lessonColor.r, lesson.lessonColor.g, lesson.lessonColor.b, mouseArea.containsMouse ? 0.8 : 0) : "transparent"
        border.width: 2
        
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // Detail popup
    Popup {
        id: lessonPopup
        parent: Overlay.overlay
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 320
        modal: true
        
        background: Rectangle {
            color: "#2D2D2D"
            radius: 16
            border.color: Qt.rgba(255, 255, 255, 0.1)
            border.width: 1
        }
        
        contentItem: ColumnLayout {
            spacing: 16
            
            // Header with color bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                radius: 12
                color: lesson ? Qt.rgba(lesson.lessonColor.r, lesson.lessonColor.g, lesson.lessonColor.b, 0.3) : "#FF6B35"
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: lesson ? lesson.subject : ""
                        font.pixelSize: 18
                        font.bold: true
                        font.strikeout: lesson && lesson.status === 1
                    }
                    
                    Label {
                        Layout.alignment: Qt.AlignHCenter
                        text: lesson ? lesson.statusText : ""
                        font.pixelSize: 12
                        color: {
                            if (!lesson) return "#AAAAAA"
                            switch (lesson.status) {
                                case 1: return "#FF6B6B"
                                case 2: return "#FFD93D"
                                default: return "#AAAAAA"
                            }
                        }
                        visible: text.length > 0
                    }
                }
            }
            
            // Details
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 12
                columnSpacing: 16
                
                Label { text: "Time"; color: "#888888"; font.pixelSize: 12 }
                Label { 
                    text: lesson ? Qt.formatTime(lesson.startTime, "HH:mm") + " - " + Qt.formatTime(lesson.endTime, "HH:mm") : ""
                    font.pixelSize: 12 
                }
                
                Label { text: "Period"; color: "#888888"; font.pixelSize: 12 }
                Label { text: lesson ? lesson.hourNumber : ""; font.pixelSize: 12 }
                
                Label { text: "Teacher"; color: "#888888"; font.pixelSize: 12; visible: lesson && lesson.teacher.length > 0 }
                Label { 
                    text: lesson ? lesson.teacher : ""
                    font.pixelSize: 12
                    visible: lesson && lesson.teacher.length > 0
                }
                
                Label { text: "Room"; color: "#888888"; font.pixelSize: 12; visible: lesson && lesson.room.length > 0 }
                Label { 
                    text: lesson ? lesson.room : ""
                    font.pixelSize: 12
                    visible: lesson && lesson.room.length > 0
                }
                
                // Original teacher if changed
                Label { 
                    text: "Original Teacher"
                    color: "#888888"
                    font.pixelSize: 12
                    visible: lesson && lesson.originalTeacher.length > 0
                }
                Label { 
                    text: lesson ? lesson.originalTeacher : ""
                    font.pixelSize: 12
                    color: "#FF6B6B"
                    visible: lesson && lesson.originalTeacher.length > 0
                }
                
                // Comment
                Label { 
                    text: "Note"
                    color: "#888888"
                    font.pixelSize: 12
                    visible: lesson && lesson.comment.length > 0
                }
                Label { 
                    text: lesson ? lesson.comment : ""
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    visible: lesson && lesson.comment.length > 0
                }
            }
            
            Button {
                Layout.alignment: Qt.AlignRight
                text: "Close"
                flat: true
                onClicked: lessonPopup.close()
            }
        }
    }
}
