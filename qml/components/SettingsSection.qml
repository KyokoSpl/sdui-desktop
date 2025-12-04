import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ColumnLayout {
    id: settingsSection
    
    property string title: ""
    
    Layout.fillWidth: true
    spacing: 0
    
    Rectangle {
        Layout.fillWidth: true
        height: 40
        color: "#252525"
        
        Label {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: settingsSection.title
            font.pixelSize: 12
            font.weight: Font.Medium
            color: "#FF6B35"
        }
    }
}
