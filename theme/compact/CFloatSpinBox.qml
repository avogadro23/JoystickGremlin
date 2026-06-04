// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import "../../qml" as BaseQml

BaseQml.FloatSpinBox {
    spinboxComponent: _compactSpinboxComponent

    Component {
        id: _compactSpinboxComponent
        SpinBox {}
    }
}
