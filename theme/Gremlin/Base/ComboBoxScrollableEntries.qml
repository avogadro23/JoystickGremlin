// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls

ListView {
    id: _list

    property int scrollStep: 3
    property bool showScrollBar: true

    clip: true
    implicitHeight: contentHeight
    highlightMoveDuration: 0

    ScrollBar.vertical: ScrollBar {
        policy: _list.showScrollBar ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
    }

    WheelHandler {
        onWheel: (event) => {
            const topIndex = Math.max(0, _list.indexAt(0, _list.contentY + 1))
            if (event.angleDelta.y > 0) {
                _list.positionViewAtIndex(
                    Math.max(0, topIndex - _list.scrollStep),
                    ListView.Beginning
                )
            } else {
                _list.positionViewAtIndex(
                    Math.min(_list.count - 1, topIndex + _list.scrollStep),
                    ListView.Beginning
                )
            }
            event.accepted = true
        }
    }
}
