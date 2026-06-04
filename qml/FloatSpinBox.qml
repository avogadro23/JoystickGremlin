// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls


Item {
    id: _root

    // Callers assign a Component here — e.g. a compact SpinBox variant
    property Component spinboxComponent: _defaultSpinboxComponent

    // Expose the live instance so callers can bind to it if needed
    readonly property alias spinboxItem: _loader.item

    property real minValue: -10.0
    property real maxValue: 10.0
    property real stepSize: 0.1
    property real value: 0.0
    property int decimals: 2
    property bool _internalUpdate: false

    readonly property int decimalFactor: Math.pow(10, _root.decimals)

    signal valueModified(real value)

    implicitWidth: _loader.implicitWidth
    implicitHeight: _loader.implicitHeight


    function toFloat(value) {
        return value / decimalFactor
    }

    function toInt(value) {
        return value * decimalFactor
    }

    Component {
        id: _defaultSpinboxComponent
        SpinBox {}
    }

    Loader {
        id: _loader
        sourceComponent: _root.spinboxComponent

        onLoaded: () => {
            item.from = toInt(_root.minValue)
            item.to = toInt(_root.maxValue)
            item.stepSize = toInt(_root.stepSize)
            item.editable = true

            item.validator = Qt.createQmlObject(
                "import QtQuick; DoubleValidator { " +
                    "bottom: " + toInt(_root.minValue) + "; " +
                    "top: " + toInt(_root.maxValue) + "; " +
                    "decimals: " + _root.decimals + "; " +
                    "notation: DoubleValidator.StandardNotation " +
                "}",
                _loader
            )

            // Set conversion functions before value so the initial displayText
            // is formatted correctly (setting value triggers displayText to
            // re-evaluate textFromValue, which must already be the custom one).
            item.textFromValue = (value, locale) => {
                return Number(value / decimalFactor)
                    .toLocaleString(locale, "f", _root.decimals)
            }

            item.valueFromText = (text, locale) => {
                return Number.fromLocaleString(locale, text) * decimalFactor
            }

            item.value = toInt(_root.value)

            item.valueChanged.connect(() => {
                if (!_root._internalUpdate) {
                    _root.value = toFloat(item.value)
                    _root.valueModified(_root.value)
                }
            })

            _textMetrics.font = item.font
        }
    }

    onValueChanged: () => {
        if (_loader.item && !_root._internalUpdate) {
            _internalUpdate = true
            _loader.item.value = toInt(value)
            Qt.callLater(() => { _internalUpdate = false })
        }
    }

    // Calculate the width needed for the widest possible value.
    // Component.onCompleted: {
    //     var testValues = [
    //         Number(minValue).toFixed(decimals),
    //         Number(maxValue).toFixed(decimals),
    //         Number(0).toFixed(decimals)
    //     ]

    //     for (var i = 0; i < testValues.length; i++) {
    //         _textMetrics.text = testValues[i]
    //         _spinbox.width = Math.max(_spinbox.width, _textMetrics.width)
    //     }

    //     _spinbox.width += 10
    // }

    // Handle external changes and prevent binding loops.
    // onValueChanged: () => {
    //     _internalUpdate = true
    //     _spinbox.value = toInt(value)
    //     Qt.callLater(() => { _internalUpdate = false })
    // }

    // SpinBox {
    //     id: _spinbox

    //     from: toInt(_root.minValue)
    //     to: toInt(_root.maxValue)
    //     stepSize: toInt(_root.stepSize)

    //     editable: true

    //     validator: DoubleValidator {
    //         bottom: Math.min(_spinbox.from, _spinbox.to)
    //         top:  Math.max(_spinbox.from, _spinbox.to)
    //         decimals: _root.decimals
    //         notation: DoubleValidator.StandardNotation
    //     }

    //     textFromValue: (value, locale) => {
    //         return Number(value / decimalFactor)
    //             .toLocaleString(locale, "f", _root.decimals)
    //     }

    //     valueFromText: (text, locale) => {
    //         return Number.fromLocaleString(locale, text) * decimalFactor
    //     }

    //     onValueChanged: () => {
    //         if (!_root._internalUpdate) {
    //             _root.value = toFloat(value)
    //             _root.valueModified(_root.value)
    //         }
    //     }
    // }

    TextMetrics {
        id: _textMetrics
    }
}

