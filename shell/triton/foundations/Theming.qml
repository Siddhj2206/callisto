pragma Singleton
import QtQuick
import qs.tokens

// Finds the color scheme an item should draw with.
QtObject {
    function of(item) {
        for (let node = item; node; node = node.parent) {
            if (node.themeScheme !== undefined)
                return node.themeScheme;
        }
        return Colors.current;
    }
}
