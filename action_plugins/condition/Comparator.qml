// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import Gremlin.ActionPlugins
import Gremlin.Base
import Gremlin.Compact as Compact
import Gremlin.Style
import Gremlin.Util


Item {
    property var comparator : null

    implicitWidth: _content.implicitWidth
    implicitHeight: _content.implicitHeight

    RowLayout {
        id: _content

        Loader {
            active: comparator && comparator.typeName === "pressed"

            Layout.preferredWidth: active ? implicitWidth : 0

            sourceComponent: RowLayout {
                Compact.ButtonStateSelector {
                    isPressed: comparator.isPressed
                    onStateModified: (isPressed) => {
                        comparator.isPressed = isPressed
                    }
                }
            }
        }

        Loader {
            active: comparator && comparator.typeName === "range"

            Layout.preferredWidth: active ? implicitWidth : 0

            sourceComponent: RowLayout {
                Label { text: "between" }

                Compact.FloatSpinBox {
                    id: _lower

                    minValue: -1.0
                    maxValue: _upper.value
                    stepSize: 0.05
                    decimals: Style.decimalsPrecise
                    value: active ? comparator.lowerLimit : 0.0

                    onValueModified: (newValue) => {
                        comparator.lowerLimit = newValue
                    }
                }

                Label { text: "and" }

                Compact.FloatSpinBox {
                    id: _upper

                    minValue: _lower.value
                    maxValue: 1.0
                    stepSize: 0.05
                    decimals: Style.decimalsPrecise
                    value: active ? comparator.upperLimit : 0.0

                    onValueModified: (newValue) => {
                        comparator.upperLimit = newValue
                    }
                }
            }
        }

        Loader {
            active: comparator && comparator.typeName === "direction"

            Layout.preferredWidth: active ? implicitWidth : 0

            sourceComponent: RowLayout {
                Compact.HatDirectionSelectorV2 {
                    directions: active ? comparator.model : null
                }
            }
        }
    }
}