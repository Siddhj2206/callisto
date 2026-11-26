pragma ComponentBehavior: Bound

import QtQuick
import ".."
import "../components"

// The launcher (Launcher board): a Thick Glass modal panel over a 30% scrim.
// Three states share one search row:
//
//   apps     — 900px wide: top-hit card + grouped result rows + kbd footer
//   calc     — 572px wide: display-size result with copy/open actions
//   commands — 572px wide: command rows, tertiary-tinted chip, no footer
//
// The state is derived from the query prefix (= / >) but the caller passes it
// explicitly: this component is a leaf — state derivation and results live in
// the launcher controller, so the dev harness can drive every state directly.
//
// Interaction contract: the panel owns keyboard navigation of its result list
// (up/down/enter/tab per the footer hints) and emits activated(index) /
// closed. The search input is a real TextInput — in production it takes focus
// when the panel opens; in the dev harness text is injected by the mock.

Rectangle {
    id: root

    enum Mode { Apps, Calc, Commands }

    property int mode: LauncherPanel.Mode.Apps

    // Query text shown in the search row. In production this is two-way bound
    // to the input; the caret renders inside it.
    property string query: ""
    // Mode-specific search-row identity.
    property string badgeGlyph: root.mode === LauncherPanel.Mode.Commands ? Icons.chevronRight
                              : root.mode === LauncherPanel.Mode.Calc ? Icons.calculate
                              : Icons.search
    property color badgeColor: root.mode === LauncherPanel.Mode.Commands ? Theme.tertiary : Theme.primary
    property color badgeGlyphColor: root.mode === LauncherPanel.Mode.Commands ? Theme.ontertiary : Theme.onprimary

    // Filter chips (apps mode).
    property var chips: ["All", "Apps", "Files", "Windows"]
    property int activeChip: 0

    // Result model: flat list for the rows column. Each entry:
    // { kind: "label"|"row", text?, glyph?, fillGlyph?, title?, subtitle?,
    //   tag?, discColor?, discContentColor?, selected? }
    property var results: []

    // Top hit (apps mode).
    property string topHitGlyph: ""
    property string topHitName: ""
    property string topHitSubtitle: ""
    property var topHitActions: [] // [{text, icon?, veil?}]

    // Calc mode.
    property string calcExpression: ""
    property string calcResult: ""

    // Interaction state.
    property bool grabsFocus: true
    // Index into the selectable rows (labels skipped) currently highlighted.
    property int selection: 0

    signal activated(int idx)
    signal actionClicked(int idx)
    signal chipClicked(int idx)
    signal queryEdited(string text)
    signal closed

    // Keyboard navigation per the footer hints. Returns true if handled.
    function keyPressed(event) {
        console.log("KEY:", event.key);
        const rows = results.filter(r => r.kind !== "label");
        if (event.key === Qt.Key_Down) {
            selection = Math.min(selection + 1, rows.length - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            selection = Math.max(selection - 1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activated(selection);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            closed();
            event.accepted = true;
        }
    }

    onQueryChanged: input.text = root.query

    Timer {
        interval: 2000
        running: true
        repeat: false
        onTriggered: console.log("FOCUS input:", input.activeFocus, "panel window focus:", root.Window.window ? root.Window.window.activeFocusItem !== null : "no-window")
    }

    // Focus arrives with window activation, not component completion — layer
    // surfaces are granted keyboard focus by the compositor after mapping,
    // and on slow compositors (llvmpipe) that lands well after construction.
    Connections {
        target: root.Window.window
        function onActiveChanged() {
            if (root.Window.window && root.Window.window.active && root.grabsFocus)
                input.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        input.text = root.query;
        if (grabsFocus)
            input.forceActiveFocus();
    }

    width: root.mode === LauncherPanel.Mode.Apps ? 900 : 572
    height: contentCol.implicitHeight
    radius: 28
    color: Theme.thickGlassBg
    clip: true

    Column {
        id: contentCol
        width: parent.width

        // ---- Search row: h72, padding 0 16 0 14, gap 14 ----
        Item {
            width: parent.width
            height: 72

            Row {
                x: 14
                height: parent.height
                spacing: 14

                WaveShape {
                    size: 40
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.badgeColor
                    glyph: root.badgeGlyph
                    glyphColor: root.badgeGlyphColor
                    glyphSize: 24
                }

                // The query is a real input: the launcher takes focus when it
                // opens, and typing is the whole point of the surface. The
                // caret is the board's 2x26 primary bar — TextInput's own
                // cursor matches it exactly (width 2, primary).
                // Navigation interceptor: Qt dispatches key events to this
                // item (the input's parent in the focus chain) FIRST when the
                // input forwards. Keys the launcher owns are consumed here;
                // the rest continue to the input's editing behavior.
                Item {
                    id: queryNavKeys
                    width: 0
                    height: 0
                    Keys.onPressed: event => {
                        console.log("NAVKEY interceptor saw:", event.key);
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Up ||
                            event.key === Qt.Key_Return || event.key === Qt.Key_Enter ||
                            event.key === Qt.Key_Escape) {
                            root.keyPressed(event);
                            event.accepted = true;
                        } else {
                            event.accepted = false;
                        }
                    }
                }

                TextInput {
                    id: input
                    width: Math.max(2, inputMetrics.advanceWidth) + 4
                    height: parent.height
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: "Google Sans Flex Medium"
                    font.pixelSize: 24
                    font.letterSpacing: -0.2
                    color: Theme.onsurface
                    cursorVisible: input.activeFocus
                    cursorDelegate: Rectangle {
                        width: 2
                        height: 26
                        color: Theme.primary
                        visible: input.cursorVisible
                    }
                    onTextEdited: root.queryEdited(input.text)

                    // TextInput consumes navigation keys internally before
                    // attached Keys handlers fire. The input is wrapped in a
                    // parent FocusScope (queryWrap below) that intercepts
                    // first and only forwards what it doesn't use.
                    Keys.forwardTo: [queryNavKeys]

                    TextMetrics {
                        id: inputMetrics
                        font: input.font
                        text: input.text
                    }
                }
            }

            // Chips trailing (apps: filters, commands: tinted Commands chip).
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Repeater {
                    model: root.mode === LauncherPanel.Mode.Apps ? root.chips
                         : root.mode === LauncherPanel.Mode.Commands ? ["Commands"] : []

                    TritonChip {
                        required property int index
                        required property string modelData
                        text: modelData
                        selected: root.mode === LauncherPanel.Mode.Commands ? true : index === root.activeChip
                        selectedFill: root.mode === LauncherPanel.Mode.Commands ? Theme.tertiaryContainer : Theme.secondaryContainer
                        selectedContent: root.mode === LauncherPanel.Mode.Commands ? Theme.ontertiarycontainer : Theme.onsecondarycontainer
                        onClicked: root.chipClicked(index)
                    }
                }
            }
        }

        // ---- Divider: 1px, white 12% ----
        Rectangle {
            width: parent.width
            height: 1
            color: "#1FFFFFFF"
        }

        // ---- Body per mode ----
        Loader {
            width: parent.width
            sourceComponent: root.mode === LauncherPanel.Mode.Apps ? appsBody
                           : root.mode === LauncherPanel.Mode.Calc ? calcBody
                           : commandsBody
        }

        // ---- Footer: kbd hints, apps mode only ----
        Item {
            visible: root.mode === LauncherPanel.Mode.Apps
            width: parent.width
            height: visible ? 53 : 0 // 52 content + divider above already counted

            Rectangle {
                width: parent.width
                height: 1
                color: "#1FFFFFFF"
            }

            Row {
                x: 20
                height: 52
                spacing: 22

                Repeater {
                    model: [
                        { keys: [], glyphs: [Icons.keyboardArrowUp, Icons.keyboardArrowDown], label: "move" },
                        { keys: ["Enter"], glyphs: [], label: "open" },
                        { keys: ["Tab"], glyphs: [], label: "actions" },
                        { keys: ["Alt", "Enter"], glyphs: [], label: "reveal" },
                    ]

                    Row {
                        required property var modelData
                        property var hint: modelData
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // Keys need their own row: a Repeater parents its
                        // delegates to itself, not to the outer layout, so
                        // without this they stack at the origin.
                        Row {
                            spacing: 4

                            Repeater {
                                model: parent.parent.hint.glyphs

                                Rectangle {
                                    required property string modelData
                                    height: 24
                                    width: 24
                                    radius: 7
                                    color: "transparent"
                                    border.width: 1
                                    border.color: "#4DFFFFFF"

                                    TritonIcon {
                                        anchors.centerIn: parent
                                        glyph: parent.modelData
                                        size: 16
                                        color: Theme.onsurface
                                    }
                                }
                            }

                            Repeater {
                                model: parent.parent.hint.keys

                                Rectangle {
                                    required property string modelData
                                    height: 24
                                    width: Math.max(24, keyText.implicitWidth + 12)
                                    radius: 7
                                    color: "transparent"
                                    border.width: 1
                                    border.color: "#4DFFFFFF" // white 30%

                                    TritonText {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: parent.modelData
                                        family: TritonText.Family.Mono
                                        weight: TritonText.Weight.SemiBold
                                        font.pixelSize: 12
                                        color: Theme.onsurface
                                    }
                                }
                            }
                        }

                        TritonText {
                            text: parent.hint.label
                            font.pixelSize: 13
                            color: Theme.onsurfacevariant
                        }
                    }
                }
            }

            // Esc close, right-aligned.
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    height: 24
                    width: Math.max(24, escText.implicitWidth + 12)
                    radius: 7
                    color: "transparent"
                    border.width: 1
                    border.color: "#4DFFFFFF"

                    TritonText {
                        id: escText
                        anchors.centerIn: parent
                        text: "Esc"
                        family: TritonText.Family.Mono
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 12
                        color: Theme.onsurface
                    }
                }

                TritonText {
                    text: "close"
                    font.pixelSize: 13
                    color: Theme.onsurfacevariant
                }
            }
        }
    }

    // ---- Body components ----
    Component {
        id: appsBody

        Item {
            width: root.width
            height: bodyRow.implicitHeight + 28

            Row {
                id: bodyRow
                x: 14
                y: 14
                spacing: 14

                // Top hit card: w310 r24 primary-container, padding 20.
                // Height pinned to the results column — the card is the
                // fixed-width leaf; the rows determine how tall the body is.
                Rectangle {
                    width: 310
                    height: resultsCol.implicitHeight
                    radius: 24
                    color: Theme.primaryContainer

                    Column {
                        x: 20
                        y: 20
                        width: parent.width - 40
                        spacing: 14

                        TritonText {
                            text: "Top hit"
                            weight: TritonText.Weight.SemiBold
                            font.pixelSize: 12
                            font.letterSpacing: 1.7 // .14em at 12px
                            font.capitalization: Font.AllUppercase
                            color: Theme.onprimarycontainer
                            opacity: 0.85
                        }

                        Rectangle {
                            width: 96
                            height: 96
                            radius: 48
                            color: Theme.primary

                            TritonIcon {
                                anchors.centerIn: parent
                                glyph: root.topHitGlyph
                                fill: true
                                size: 44
                                color: Theme.onprimary
                            }
                        }

                        Column {
                            spacing: 6

                            TritonText {
                                text: root.topHitName
                                family: TritonText.Family.Display
                                weight: TritonText.Weight.SemiBold
                                font.pixelSize: 40
                                font.letterSpacing: -0.6
                                color: Theme.onprimarycontainer
                            }
                            TritonText {
                                text: root.topHitSubtitle
                                font.pixelSize: 14
                                color: Theme.onprimarycontainer
                                opacity: 0.85
                            }
                        }
                    }

                    // Board: actions sit at the card's bottom edge
                    // (margin-top:auto in the flex column).
                    Row {
                        x: 20
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 20
                        spacing: 8

                        Repeater {
                            model: root.topHitActions

                            TritonButton {
                                required property var modelData
                                text: modelData.text || ""
                                icon: modelData.icon || ""
                                variant: modelData.veil ? TritonButton.Variant.Veil : TritonButton.Variant.Filled
                                contentOverride: modelData.veil ? "#D9E2FF" : ""
                            }
                        }
                    }
                }

                // Results column.
                Column {
                    id: resultsCol
                    width: root.width - 28 - 310 - 14

                    Repeater {
                        model: root.results

                        delegate: Item {
                            required property var modelData
                            required property int index
                            // Board `.lbl` box: padding 12/12/6 around a 17px
                            // line, so a label occupies 35px of the column.
                            // The first label overrides to padding-top 2
                            // (board inline style) and drops the bottom
                            // padding visually into the row — 26px there.
                            width: parent.width
                            height: modelData.kind === "label" ? (index === 0 ? 26 : 35) : 56

                            TritonText {
                                id: lbl
                                visible: modelData.kind === "label"
                                x: 12
                                y: modelData.kind === "label" ? (index === 0 ? 2 : 12) : 0
                                text: modelData.text || ""
                                weight: TritonText.Weight.SemiBold
                                font.pixelSize: 12
                                font.letterSpacing: 1.7
                                font.capitalization: Font.AllUppercase
                                color: Theme.onsurfacevariant
                            }

                            ResultRow {
                                visible: modelData.kind !== "label"
                                width: parent.width
                                glyph: modelData.glyph || ""
                                fillGlyph: modelData.fillGlyph || false
                                title: modelData.title || ""
                                subtitle: modelData.subtitle || ""
                                tag: modelData.tag || ""
                                keyHint: modelData.keyHint || ""
                                selected: modelData.selected !== undefined ? modelData.selected
                                          : root.results.slice(0, index).filter(r => r.kind !== "label").length === root.selection
                                discColor: modelData.discColor || Theme.secondaryContainer
                                discContentColor: modelData.discContentColor || Theme.onsecondarycontainer
                                useDisc: modelData.useDisc !== undefined ? modelData.useDisc : true
                                onClicked: root.activated(index)
                            }
                        }
                    }
                }
            }

        }
    }

    Component {
        id: calcBody

        Item {
            width: root.width
            height: calcRow.implicitHeight + 40

            Row {
                id: calcRow
                x: 24
                y: 20
                width: parent.width - 48
                spacing: 16

                Column {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    TritonText {
                        text: root.calcExpression
                        font.pixelSize: 14
                        color: Theme.onsurfacevariant
                    }
                    TritonText {
                        text: root.calcResult
                        family: TritonText.Family.Display
                        weight: TritonText.Weight.SemiBold
                        font.pixelSize: 64
                        font.letterSpacing: -1.5
                        color: Theme.onsurface
                    }
                }

                Item { width: 1; height: 1 } // slack

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    TritonButton {
                        icon: Icons.contentCopy
                        text: "Copy"
                    }
                    TritonButton {
                        text: "Open Calculator"
                        variant: TritonButton.Variant.Veil
                    }
                }
            }
        }
    }

    Component {
        id: commandsBody

        Item {
            width: root.width
            height: cmdCol.implicitHeight + 22

            Column {
                id: cmdCol
                x: 10
                y: 10
                width: parent.width - 20
                spacing: 2

                Repeater {
                    model: root.results

                    ResultRow {
                        required property var modelData
                        required property int index
                        glyph: modelData.glyph || ""
                        fillGlyph: modelData.fillGlyph || false
                        title: modelData.title || ""
                        subtitle: modelData.subtitle || ""
                        keyHint: modelData.keyHint || ""
                        selected: modelData.selected || false
                        useDisc: false
                        onClicked: root.activated(index)
                    }
                }
            }
        }
    }
}
