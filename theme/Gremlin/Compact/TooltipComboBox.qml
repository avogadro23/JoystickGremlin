// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Templates as T
import Gremlin.Base as Base
import Gremlin.Compact as Compact

Compact.ComboBox {
    id: control

    property bool enableTooltips: true
    property int scrollStep: 3

    delegate: ItemDelegate {
        required property var model
        required property int index

        width: ListView.view.width
        text: model[control.textRole]
        font.pixelSize: 14
        topPadding: 4
        bottomPadding: 4
        font.weight: control.currentIndex === index ? Font.DemiBold : Font.Normal
        highlighted: control.highlightedIndex === index
        hoverEnabled: control.hoverEnabled

        Base.WrappingTooltip {
            text: parent.text
            visible: parent.hovered && control.enableTooltips
        }
    }

    popup: T.Popup {
        width: control.width
        height: Math.min(contentItem.implicitHeight, control.Window.height - topMargin - bottomMargin)
        topMargin: 4
        bottomMargin: 4

        Universal.theme: control.Universal.theme
        Universal.accent: control.Universal.accent

        contentItem: Base.ComboBoxScrollableEntries {
            model: control.delegateModel
            currentIndex: control.highlightedIndex
            scrollStep: control.scrollStep
        }

        background: Rectangle {
            color: control.Universal.chromeMediumLowColor
            border.color: control.Universal.chromeHighColor
            border.width: 1
        }
    }

    Base.WrappingTooltip {
        text: control.currentText
        visible: _hoverHandler.hovered && control.enableTooltips
    }

    HoverHandler {
        id: _hoverHandler
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}
