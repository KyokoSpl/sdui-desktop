import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

// Glass-morphism card component (inspired by the Android GlassCard)
Rectangle {
    id: glassCard
    
    property alias contentItem: contentLoader.sourceComponent
    property real glassOpacity: 0.85
    property real blurRadius: 20
    
    radius: 16
    color: Qt.rgba(30/255, 30/255, 30/255, glassOpacity)
    border.color: Qt.rgba(255, 255, 255, 0.1)
    border.width: 1
    
    // Subtle shadow
    layer.enabled: true
    layer.effect: Item {
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: glassCard.radius + 2
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.3)
            border.width: 4
            z: -1
        }
    }
    
    Loader {
        id: contentLoader
        anchors.fill: parent
        anchors.margins: 16
    }
}
