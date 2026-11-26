pragma ComponentBehavior: Bound

import QtQuick

// Renders one wallpaper thumbnail. Image wallpapers load their file;
// generative wallpapers are authored scenes — the same scene definitions the
// Desktop layer uses full-screen, so a thumbnail is an honest preview.

Item {
    id: root

    property string kind: "image"
    property string path: ""

    clip: true

    Image {
        visible: root.kind === "image"
        anchors.fill: parent
        source: root.path !== "" ? "file://" + root.path : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    // Nebula: radial violet/blue over deep space.
    Rectangle {
        visible: root.kind === "nebula"
        anchors.fill: parent
        color: "#0B0D24"
        Rectangle {
            x: parent.width * 0.3 - width / 2
            y: parent.height * 0.4 - height / 2
            width: parent.width * 0.9
            height: width
            radius: width / 2
            color: "#6B3FA0"
            opacity: 0.55
        }
        Rectangle {
            x: parent.width * 0.75 - width / 2
            y: parent.height * 0.6 - height / 2
            width: parent.width * 0.95
            height: width
            radius: width / 2
            color: "#1F4FBF"
            opacity: 0.5
        }
    }

    // Dune: sun disc over desert gradient.
    Rectangle {
        visible: root.kind === "dune"
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#E58A4B" }
            GradientStop { position: 1.0; color: "#7C4A2C" }
        }
        Rectangle {
            x: parent.width * 0.7 - width / 2
            y: parent.height * 0.35 - height / 2
            width: parent.width * 0.16
            height: width
            radius: width / 2
            color: "#FFD9A8"
        }
    }

    // Ice: diagonal cold gradient.
    Rectangle {
        visible: root.kind === "ice"
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#9FE0E0" }
            GradientStop { position: 0.6; color: "#2F7F9A" }
            GradientStop { position: 1.0; color: "#0F2A44" }
        }
        rotation: 20
        scale: 1.6
    }

    // Dusk: night-to-ember vertical.
    Rectangle {
        visible: root.kind === "dusk"
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0F1A3A" }
            GradientStop { position: 0.6; color: "#4A2C5C" }
            GradientStop { position: 1.0; color: "#C0552A" }
        }
    }

    // Planet: blue arc over deep navy.
    Rectangle {
        visible: root.kind === "planet"
        anchors.fill: parent
        color: "#0B1430"
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.55
            width: parent.width * 1.2
            height: width
            radius: width / 2
            color: "#2458C8"
        }
    }

    // Paper: near-white gradient.
    Rectangle {
        visible: root.kind === "paper"
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#EEF1F8" }
            GradientStop { position: 1.0; color: "#CBD3E4" }
        }
    }
}
