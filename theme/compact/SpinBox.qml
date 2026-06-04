// Copyright (C) 2017 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR LGPL-3.0-only OR GPL-2.0-only OR GPL-3.0-only
// Modified by Joystick Gremlin Contributors

import QtQuick
import QtQuick.Controls.impl
import QtQuick.Templates as T
import QtQuick.Controls.Universal

T.SpinBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 2
    leftPadding: padding + (control.mirrored ? (up.indicator ? up.indicator.width : 0)
                                             : (down.indicator ? down.indicator.width : 0))
    rightPadding: padding + (control.mirrored ? (down.indicator ? down.indicator.width : 0)
                                              : (up.indicator ? up.indicator.width : 0))

    font.pixelSize: 14
    inputMethodHints: Qt.ImhFormattedNumbersOnly

    validator: IntValidator {
        locale: control.locale.name
        bottom: Math.min(control.from, control.to)
        top: Math.max(control.from, control.to)
    }

    contentItem: TextInput {
        z: 2
        text: control.displayText
        font: control.font
        color: !control.enabled ? control.Universal.chromeDisabledLowColor
                                : control.Universal.foreground
        selectionColor: control.Universal.accent
        selectedTextColor: control.Universal.chromeWhiteColor
        horizontalAlignment: Qt.AlignHCenter
        verticalAlignment: Qt.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: control.inputMethodHints
        clip: width < implicitWidth
    }

    up.indicator: Rectangle {
        x: control.mirrored ? 0 : parent.width - width
        height: parent.height
        implicitWidth: 24
        implicitHeight: 24
        color: control.up.pressed ? control.Universal.baseMediumLowColor
             : control.up.hovered ? control.Universal.baseLowColor
             : "transparent"

        Text {
            text: "+"
            font.pixelSize: 14
            color: !control.up.enabled ? control.Universal.chromeDisabledLowColor
                                       : control.Universal.baseHighColor
            anchors.centerIn: parent
        }
    }

    down.indicator: Rectangle {
        x: control.mirrored ? parent.width - width : 0
        height: parent.height
        implicitWidth: 24
        implicitHeight: 24
        color: control.down.pressed ? control.Universal.baseMediumLowColor
             : control.down.hovered ? control.Universal.baseLowColor
             : "transparent"

        Text {
            text: "−"
            font.pixelSize: 14
            color: !control.down.enabled ? control.Universal.chromeDisabledLowColor
                                         : control.Universal.baseHighColor
            anchors.centerIn: parent
        }
    }

    background: Rectangle {
        implicitWidth: 120
        implicitHeight: 24
        border.color: !control.enabled ? control.Universal.baseLowColor
                    : control.activeFocus ? control.Universal.accent
                    : control.Universal.baseMediumLowColor
        border.width: control.activeFocus ? 2 : 1
        color: !control.enabled ? control.Universal.baseLowColor
             : control.editable ? control.Universal.background
             : control.Universal.altMediumLowColor
    }
}
