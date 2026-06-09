// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Layouts

RoundButton {
    property alias description: _description.text

    contentItem: RowLayout {
        spacing: 4
        anchors.centerIn: parent

        Label {
            Layout.leftMargin: 4
            Layout.alignment: Qt.AlignVCenter
            text: "\uF518"
            font.family: "bootstrap-icons"
        }
        Label {
            id: _description
            Layout.alignment: Qt.AlignBaseline
            Layout.rightMargin: 4
            text: "Rec"
        }
    }
}
