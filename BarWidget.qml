import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  readonly property real contentWidth: content.implicitWidth + Style.marginM * 2
  readonly property real contentHeight: capsuleHeight

  implicitWidth: contentWidth
  implicitHeight: contentHeight

  property var timerData: ({text: "0:00", "class": "white"})
  property string serverUrl: "http://localhost:2420"

  property color timerColor: {
    switch (timerData["class"]) {
      case "green":  return "#00ff00"
      case "yellow": return "#FFFF00"
      case "red":    return "#FF0000"
      default:       return Color.mOnSurface
    }
  }

  Process {
    id: configReader
    command: ["python3", "-c", "import json; d=json.load(open('/home/jthorne/.config/ChillClock/config.json')); print(d.get('server_url','http://localhost:2420'))"]
    stdout: StdioCollector {}
    onExited: {
      var url = configReader.stdout.text.trim()
      if (url) root.serverUrl = url
    }
  }

  Component.onCompleted: configReader.running = true

  Process {
    id: timerProcess
    command: ["curl", "-s", root.serverUrl + "/status"]
    stdout: StdioCollector {}
    onExited: {
      try {
        root.timerData = JSON.parse(timerProcess.stdout.text.trim())
      } catch(_) {}
    }
  }

  Timer {
    interval: 500
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: timerProcess.running = true
  }

  Process {
    id: togglePrimary
    command: ["curl", "-s", "-X", "POST", root.serverUrl + "/toggle?timer=1"]
  }

  Process {
    id: toggleSecondary
    command: ["curl", "-s", "-X", "POST", root.serverUrl + "/toggle?timer=2"]
  }
  

  Rectangle {
    id: visualCapsule
    x: Style.pixelAlignCenter(parent.width, width)
    y: Style.pixelAlignCenter(parent.height, height)
    width: root.contentWidth
    height: root.contentHeight
    color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
    radius: Style.radiusL
    border.color: Style.capsuleBorderColor
    border.width: Style.capsuleBorderWidth

    RowLayout {
      id: content
      anchors.centerIn: parent
      spacing: Style.marginS

      NText {
        text: root.timerData.text ?? "farts"
        pointSize: root.barFontSize
        color: root.timerColor
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        togglePrimary.running = true
      } else if (mouse.button === Qt.RightButton) {
        toggleSecondary.running = true
      }
    }
  }
}
