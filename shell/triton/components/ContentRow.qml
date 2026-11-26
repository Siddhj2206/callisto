pragma ComponentBehavior: Bound

import QtQuick

// The content row: the one true horizontal layout primitive for shell
// surfaces. It exists to make correct vertical alignment structural rather
// than remembered.
//
// Plain Qt Row positions children at y = 0, so mixed-height content ends up
// top-aligned — the "everything is everywhere" failure. This row instead:
//
//   - centers itself in its parent (in both axes — rows are content clusters)
//   - takes the parent's full height minus `inset`
//   - vertically centers EVERY child inside itself, automatically
//
// Children should be Triton atoms and controls; they never need their own
// verticalCenter anchors.

Row {
    // Pixels shaved off the row height at top and bottom — e.g. the island's
    // internal vertical padding. Rarely needed; spacing rhythm usually comes
    // from the container.
    property real inset: 0

    anchors.centerIn: parent
    height: parent.height - inset * 2

    onChildrenChanged: centerChildren()
    Component.onCompleted: centerChildren()

    function centerChildren() {
        for (let i = 0; i < children.length; i++) {
            const child = children[i];
            if (child && child.anchors)
                child.anchors.verticalCenter = verticalCenter;
        }
    }
}
