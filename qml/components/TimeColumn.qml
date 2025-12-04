import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Time column showing hour slots
Column {
    id: timeColumn
    
    property var hourSlots: []
    
    spacing: 4
    
    Repeater {
        model: hourSlots
        
        Item {
            width: 50
            height: 70
            
            property string hourNumber: modelData
            
            Column {
                anchors.centerIn: parent
                spacing: 2
                
                // Hour number badge
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 28
                    height: 28
                    radius: 14
                    color: "#FF6B35"
                    
                    Label {
                        anchors.centerIn: parent
                        text: hourNumber.replace("-", "\n")
                        font.pixelSize: hourNumber.includes("-") ? 9 : 12
                        font.bold: true
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        lineHeight: 0.8
                    }
                }
            }
        }
    }
}
