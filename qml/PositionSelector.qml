// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Gremlin.Style

Item {
    id: _root

    property int minPosition: 0
    property int maxPosition: 10
    property int selectedPosition: -1

    implicitHeight: _selector.height + _label.height

    // Position selection label
    Label {
        id: _label
        text: "Paste Position: " + selectedPosition
        font.pixelSize: 12

        Layout.topMargin: 5
        Layout.leftMargin: 5
    }

    // Position selector
    JGComboBox {
        id: _selector

        model: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        currentIndex: selectedPosition

        onCurrentIndexChanged: {
            selectedPosition = currentIndex
            backend.clipboardPosition = currentIndex
        }
    }

    function updatePositionSelector() {
        _selector.currentIndex = selectedPosition
    }
}
