pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import qs
import qs.services

// What the lock and login screens say about the machine.
Singleton {
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.ready && battery.isLaptopBattery
    readonly property int batteryPercent: hasBattery ? Math.round(battery.percentage * 100) : -1
    readonly property string batteryGlyph: !hasBattery ? ""
        : battery.state === UPowerDeviceState.Charging ? Icons.batteryChargingFull : Icons.battery5Bar
    readonly property string networkGlyph: NetworkService.wired ? Icons.lan : NetworkService.online ? Icons.wifi : ""
}
