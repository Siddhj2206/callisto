// GENERATED FILE — DO NOT EDIT.
// Produced by scripts/generate-theme.py from design/tokens.json.
// Regenerate: scripts/generate-theme.py

pragma Singleton
import Quickshell
import QtQuick

QtObject {
    readonly property bool board: Quickshell.env("CALLISTO_DENSITY") === "board"

    readonly property real trayWidth: board ? 292 : 264
    readonly property real trayTile: board ? 56 : 44
    readonly property real trayRadius: board ? 20 : 16
    readonly property real mediaTitleMax: board ? 200 : 180
    readonly property real mediaArt: board ? 40 : 28
    readonly property real mediaArtLarge: board ? 112 : 88
    readonly property real mediaWidth: board ? 440 : 400
    readonly property real waveAmplitude: board ? 3 : 2.5
    readonly property real waveLength: board ? 24 : 20
    readonly property real wavePlayed: board ? 4 : 3
    readonly property real waveRow: board ? 24 : 20
    readonly property real playButton: board ? 64 : 52
    readonly property real barHeight: board ? 56 : 36
    readonly property real barSlot: board ? 44 : 28
    readonly property real barPad: board ? 6 : 4
    readonly property real barGap: board ? 4 : 2
    readonly property real barTop: board ? 8 : 6
    readonly property real barSide: board ? 16 : 8
    readonly property real barDockedStart: board ? 10 : 6
    readonly property real barDockedEnd: board ? 8 : 4
    readonly property real workspaceSize: board ? 40 : 24
    readonly property real workspaceActive: board ? 56 : 36
    readonly property real clockStart: board ? 18 : 10
    readonly property real clockEnd: board ? 16 : 10
    readonly property real clockGap: board ? 12 : 8
    readonly property real statusPad: board ? 18 : 10
    readonly property real statusGap: board ? 16 : 10
    readonly property real titleGap: board ? 8 : 6
    readonly property real titlePad: board ? 14 : 8
    readonly property real titleMax: board ? 260 : 200
    readonly property real dividerHeight: board ? 28 : 16
    readonly property real iconSm: board ? 18 : 14
    readonly property real iconMd: board ? 22 : 16
    readonly property real iconLg: board ? 24 : 18
    readonly property real badge: board ? 10 : 7
    readonly property real badgeRing: board ? 2 : 1.5
    readonly property real badgeInset: board ? 9 : 5
    readonly property real batteryGap: board ? 6 : 4
    readonly property real ringStroke: board ? 3 : 2
    readonly property real pressRadius: board ? 12 : 8
    readonly property real focusRing: 2
    readonly property real focusOffset: 2
    readonly property real osdHeight: board ? 64 : 44
    readonly property real osdDisc: board ? 44 : 30
    readonly property real osdStart: board ? 10 : 7
    readonly property real osdEnd: board ? 22 : 16
    readonly property real osdGap: board ? 14 : 10
    readonly property real osdTrackWidth: board ? 170 : 140
    readonly property real osdTrackHeight: board ? 16 : 8
    readonly property real osdHandleWidth: board ? 4 : 3
    readonly property real osdHandleOver: board ? 5 : 3
    readonly property real osdValueWidth: board ? 44 : 30
    readonly property real osdBottom: 48
    readonly property real osdRise: 16
    readonly property real enterScale: 0.96
    readonly property real popoverTop: board ? 72 : 48
    readonly property real panelWidth: board ? 400 : 340
    readonly property real panelPad: board ? 20 : 14
    readonly property real panelGap: board ? 16 : 10
    readonly property real radiusPanelS: board ? 28 : 20
    readonly property real radiusPanelM: board ? 32 : 24
    readonly property real radiusPanelL: board ? 36 : 28
    readonly property real control: board ? 44 : 32
    readonly property real buttonHeight: board ? 48 : 36
    readonly property real buttonPad: board ? 24 : 14
    readonly property real buttonGap: board ? 8 : 6
    readonly property real tileHeight: board ? 72 : 52
    readonly property real tileGap: board ? 8 : 6
    readonly property real tilePad: 12
    readonly property real tileInnerGap: board ? 12 : 8
    readonly property real tileOnRadius: board ? 20 : 16
    readonly property real tileDrill: board ? 44 : 32
    readonly property real sliderTrack: board ? 16 : 10
    readonly property real sliderHandle: board ? 44 : 28
    readonly property real sliderHandleWidth: 4
    readonly property real sliderGap: board ? 6 : 4
    readonly property real sliderInnerRadius: 2
    readonly property real switchWidth: board ? 52 : 40
    readonly property real switchHeight: board ? 32 : 22
    readonly property real switchThumbOff: board ? 16 : 10
    readonly property real switchThumbOn: board ? 24 : 16
    readonly property real switchBorder: 2
    readonly property real rowHeight: board ? 60 : 48
    readonly property real rowPad: board ? 14 : 12
    readonly property real rowGap: board ? 14 : 10
    readonly property real listGap: 2
    readonly property real listOuter: board ? 22 : 16
    readonly property real listInner: board ? 6 : 4
    readonly property real listMax: board ? 360 : 300
    readonly property real fieldHeight: board ? 44 : 32
    readonly property real fieldPad: board ? 18 : 12
    readonly property real centerWidth: board ? 440 : 380
    readonly property real cardRadius: board ? 24 : 20
    readonly property real cardTail: board ? 10 : 8
    readonly property real listCardRadius: board ? 20 : 16
    readonly property real listCardTail: board ? 8 : 6
    readonly property real cardPad: board ? 16 : 12
    readonly property real cardGap: board ? 12 : 10
    readonly property real cardActions: 8
    readonly property real disc: board ? 48 : 36
    readonly property real discSm: board ? 32 : 28
    readonly property real peekInset: board ? 12 : 10
    readonly property real peekHeight: board ? 12 : 8
    readonly property real progressHeight: board ? 6 : 4
    readonly property real toastSlide: board ? 64 : 48
    readonly property real launcherWidth: board ? 900 : 720
    readonly property real launcherCompact: board ? 600 : 520
    readonly property real launcherHeader: board ? 72 : 56
    readonly property real launcherBody: board ? 424 : 360
    readonly property real launcherTop: 0.14
    readonly property real topHit: board ? 310 : 248
    readonly property real topHitDisc: board ? 96 : 72
    readonly property real resultRow: board ? 56 : 48
    readonly property real hintHeight: board ? 52 : 40
    readonly property real keycap: board ? 24 : 20
    readonly property real scrollbar: board ? 6 : 4
    readonly property real scrollbarWide: board ? 10 : 8
    readonly property real scrollbarHit: board ? 18 : 14
    readonly property real scrollbarInset: board ? 4 : 3
    readonly property real scrollbarThumb: board ? 40 : 32
    readonly property real powerChoice: board ? 140 : 104
    readonly property real powerExpanded: board ? 300 : 232
    readonly property real powerInner: board ? 14 : 12
    readonly property real powerSpacing: board ? 6 : 5
    readonly property real powerIcon: board ? 44 : 32
    readonly property real powerIconFocused: board ? 52 : 40
    readonly property real countdownRing: board ? 132 : 112
    readonly property real clipWidth: board ? 1000 : 760
    readonly property real clipHeight: board ? 780 : 520
    readonly property real clipList: board ? 430 : 330
    readonly property real swatch: board ? 132 : 96
    readonly property real chipHeight: board ? 36 : 28
    readonly property real lockTop: board ? 86 : 48
    readonly property real loginCard: board ? 420 : 340
    readonly property real loginBottom: board ? 116 : 64
    readonly property real avatarLarge: board ? 96 : 72
    readonly property real avatarSelected: board ? 150 : 112
    readonly property real avatarRing: board ? 180 : 136
    readonly property real brandMark: board ? 56 : 40
    readonly property real switcherWidth: board ? 1212 : 900
    readonly property real switcherCard: board ? 220 : 180
    readonly property real switcherThumb: board ? 124 : 104
    readonly property real ribbonThumb: board ? 300 : 200
    readonly property real ribbonLabel: board ? 200 : 120
    readonly property real overviewSearch: board ? 520 : 360
    readonly property real dragThreshold: 8
    readonly property real aspectMin: 0.6
    readonly property real aspectMax: 2.4
    readonly property real wallThumbWidth: board ? 200 : 160
    readonly property real wallThumbHeight: board ? 120 : 96
    readonly property real paletteWidth: board ? 370 : 300
    readonly property real captureButton: board ? 64 : 48
    readonly property real shotCard: board ? 340 : 280
    readonly property real shotThumb: board ? 170 : 140
    readonly property real countdownBadge: board ? 200 : 144
    readonly property real minSelection: 4
    readonly property real settingsWidth: board ? 1100 : 920
    readonly property real settingsHeight: board ? 760 : 640
    readonly property real settingsMinWidth: board ? 720 : 560
    readonly property real settingsMinHeight: board ? 520 : 440
    readonly property real settingsNarrow: board ? 860 : 760
    readonly property real settingsSidebar: board ? 280 : 220
    readonly property real settingsContent: board ? 760 : 720
    readonly property real settingsControl: board ? 320 : 220
    readonly property real settingsStack: board ? 560 : 480
    readonly property real settingsPad: board ? 32 : 24
    readonly property real settingsHero: board ? 200 : 168
    readonly property real optionCard: board ? 200 : 150
    readonly property real optionPreview: board ? 96 : 64
    readonly property real accentDot: board ? 48 : 30
    readonly property real lockSide: board ? 68 : 32
    readonly property real lockNotifications: board ? 380 : 300
    readonly property real lockField: board ? 56 : 44
    readonly property real shake: board ? 14 : 10

    readonly property string wavePath: "M50.00,9.80 L51.40,9.98 L52.76,10.51 L54.06,11.33 L55.29,12.38 L56.42,13.56 L57.49,14.78 L58.50,15.92 L59.48,16.92 L60.49,17.71 L61.56,18.24 L62.72,18.52 L64.00,18.56 L65.40,18.44 L66.91,18.20 L68.50,17.96 L70.13,17.78 L71.74,17.77 L73.27,17.97 L74.65,18.45 L75.84,19.21 L76.79,20.24 L77.50,21.52 L77.97,22.99 L78.23,24.58 L78.34,26.22 L78.38,27.83 L78.41,29.36 L78.53,30.76 L78.80,32.01 L79.27,33.10 L79.98,34.06 L80.93,34.92 L82.08,35.72 L83.39,36.51 L84.77,37.35 L86.13,38.26 L87.37,39.28 L88.41,40.42 L89.17,41.67 L89.59,43.02 L89.65,44.43 L89.37,45.86 L88.79,47.29 L87.97,48.67 L87.00,50.00 L85.99,51.26 L85.03,52.45 L84.22,53.60 L83.63,54.73 L83.29,55.87 L83.21,57.06 L83.39,58.32 L83.76,59.68 L84.25,61.13 L84.77,62.65 L85.22,64.23 L85.52,65.81 L85.58,67.35 L85.36,68.80 L84.81,70.10 L83.96,71.22 L82.82,72.14 L81.46,72.85 L79.94,73.39 L78.34,73.78 L76.76,74.10 L75.26,74.40 L73.90,74.75 L72.72,75.23 L71.73,75.89 L70.91,76.76 L70.23,77.84 L69.64,79.12 L69.08,80.54 L68.50,82.04 L67.83,83.54 L67.04,84.95 L66.10,86.17 L65.00,87.13 L63.75,87.78 L62.37,88.08 L60.91,88.06 L59.41,87.73 L57.90,87.16 L56.42,86.44 L55.01,85.66 L53.67,84.93 L52.40,84.33 L51.19,83.94 L50.00,83.80 L48.81,83.94 L47.60,84.33 L46.33,84.93 L44.99,85.66 L43.58,86.44 L42.10,87.16 L40.59,87.73 L39.09,88.06 L37.63,88.08 L36.25,87.78 L35.00,87.13 L33.90,86.17 L32.96,84.95 L32.17,83.54 L31.50,82.04 L30.92,80.54 L30.36,79.12 L29.77,77.84 L29.09,76.76 L28.27,75.89 L27.28,75.23 L26.10,74.75 L24.74,74.40 L23.24,74.10 L21.66,73.78 L20.06,73.39 L18.54,72.85 L17.18,72.14 L16.04,71.22 L15.19,70.10 L14.64,68.80 L14.42,67.35 L14.48,65.81 L14.78,64.23 L15.23,62.65 L15.75,61.13 L16.24,59.68 L16.61,58.32 L16.79,57.06 L16.71,55.87 L16.37,54.73 L15.78,53.60 L14.97,52.45 L14.01,51.26 L13.00,50.00 L12.03,48.67 L11.21,47.29 L10.63,45.86 L10.35,44.43 L10.41,43.02 L10.83,41.67 L11.59,40.42 L12.63,39.28 L13.87,38.26 L15.23,37.35 L16.61,36.51 L17.92,35.72 L19.07,34.92 L20.02,34.06 L20.73,33.10 L21.20,32.01 L21.47,30.76 L21.59,29.36 L21.62,27.83 L21.66,26.22 L21.77,24.58 L22.03,22.99 L22.50,21.52 L23.21,20.24 L24.16,19.21 L25.35,18.45 L26.73,17.97 L28.26,17.77 L29.87,17.78 L31.50,17.96 L33.09,18.20 L34.60,18.44 L36.00,18.56 L37.28,18.52 L38.44,18.24 L39.51,17.71 L40.52,16.92 L41.50,15.92 L42.51,14.78 L43.58,13.56 L44.71,12.38 L45.94,11.33 L47.24,10.51 L48.60,9.98Z"
}
