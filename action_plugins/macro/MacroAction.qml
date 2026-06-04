// -*- coding: utf-8; -*-
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.qmlmodels

import Gremlin.ActionPlugins
import Gremlin.Profile
import Gremlin.Style
import "../../qml"
import Compact as Compact
import "../../qml/helpers.js" as Helpers


Item {
    id: _root

    property MacroModel action

    implicitHeight: _content.height

    ColumnLayout {
        id: _content

        anchors.left: parent.left
        anchors.right: parent.right

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "<b>Repeat Mode</b>"
            }

            ComboBox {
                id: _repeatMode

                textRole: "text"
                valueRole: "value"

                Component.onCompleted: () => {
                    currentIndex = indexOfValue(_root.action.repeatMode)
                }

                onActivated: () => { _root.action.repeatMode = currentValue }

                model: [
                    {value: "single", text: "Single"},
                    {value: "count", text: "Count"},
                    {value: "toggle", text: "Toggle"},
                    {value: "hold", text: "Hold"},
                ]
            }

            Compact.FloatSpinBox {
                visible: ["count", "toggle", "hold"].includes(_repeatMode.currentValue)

                value: _root.action.repeatDelay
                minValue: 0.0
                maxValue: 3600.0

                onValueModified: (newValue) => {
                    _root.action.repeatDelay = newValue
                }
            }

            JGSpinBox {
                visible: _repeatMode.currentValue === "count"

                value: _root.action.repeatCount
                from: 1
                to: 100

                onValueModified: () => { _root.action.repeatCount = value }
            }

            LayoutHorizontalSpacer {}

            Switch {
                text: "Exclusive"

                checked: _root.action.isExclusive
                onClicked: () => { _root.action.isExclusive = checked }
            }
        }

        ActionDrop {
            targetIndex: 0
            insertionMode: "prepend"

            Layout.bottomMargin: -10
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(_actionList.contentHeight, 400)
            clip: true

            JGListView {
                id: _actionList

                width: parent.width
                spacing: 5
                scrollbarAlwaysVisible: true

                model: _root.action.actions
                delegate: _delegateChooser

                onCountChanged: () => {
                    // Update model with a delay to ensure the list view scrolls
                    // properly to the bottom.
                    Qt.callLater(positionViewAtEnd)
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10

            ComboBox {
                id: _macroAction

                Layout.preferredWidth: 150

                textRole: "text"
                valueRole: "value"

                model: [
                    {value: "joystick", text: "Joystick"},
                    {value: "key", text: "Keyboard"},
                    {value: "logical-device", text: "Logical Device"},
                    {value: "mouse-button", text: "Mouse Button"},
                    {value: "mouse-motion", text: "Mouse Motion"},
                    {value: "pause", text: "Pause"},
                    {value: "vjoy", text: "vJoy"}
                ]
            }

            Button {
                text: "Add Action"

                onClicked: () => {
                    _root.action.addAction(_macroAction.currentValue)
                }
            }

            LayoutHorizontalSpacer {}
        }

        // Action recording configuration controls.
        RowLayout {
            Layout.fillWidth: true

            CheckBox {
                text: "Keyboard"
                checked: _root.action.recordKeyboard
                onToggled: () => { _root.action.recordKeyboard = checked }
                enabled: !_root.action.isRecording
            }
            CheckBox {
                text: "Mouse"
                checked: _root.action.recordMouse
                onToggled: () => { _root.action.recordMouse = checked }
                enabled: !_root.action.isRecording
            }
            Label {
                text: "Joystick"
                Layout.leftMargin: 10
            }
            CheckBox {
                text: "Axis"
                checked: _root.action.recordJoystickAxis
                onToggled: () => { _root.action.recordJoystickAxis = checked }
                enabled: !_root.action.isRecording
            }
            CheckBox {
                text: "Button"
                checked: _root.action.recordJoystickButton
                onToggled: () => { _root.action.recordJoystickButton = checked }
                enabled: !_root.action.isRecording
            }
            CheckBox {
                text: "Hat"
                checked: _root.action.recordJoystickHat
                onToggled: () => { _root.action.recordJoystickHat = checked }
                enabled: !_root.action.isRecording
            }
            CheckBox {
                text: "Timings"
                checked: _root.action.recordTimings
                onToggled: () => { _root.action.recordTimings = checked }
                enabled: !_root.action.isRecording
            }

            LayoutHorizontalSpacer {}

            Button {
                visible: !_root.action.isRecording
                text: "Record"
                onClicked: () => { _root.action.startRecording() }
            }
            Button {
                visible: _root.action.isRecording
                highlighted: true
                text: "Stop"
                onPressed: () => { _root.action.stopRecording() }
            }
        }
    }

    // Renders the correct delegate based on the action type
    DelegateChooser {
        id: _delegateChooser

        role: "actionType"

        // Joystick action
        DelegateChoice {
            roleValue: "joystick"

            DraggableAction {
                icon: bsi.icons.icon_joystick
                label: "Joystick"

                actionItem: RowLayout {
                    InputListener {
                        buttonLabel: Helpers.safeText(
                            modelData.label, "Record Input"
                        )
                        callback: (inputs) => {
                            modelData.updateJoystick(inputs)
                        }
                        multipleInputs: false
                        eventTypes: ["axis", "button", "hat"]
                    }

                    LayoutHorizontalSpacer {}

                    // Show different components based on input
                    Compact.ButtonStateSelector {
                        visible: modelData.inputType === "button"

                        isPressed: modelData.isPressed
                        onStateModified: (isPressed) => {
                            modelData.isPressed = isPressed
                        }
                    }
                    Compact.FloatSpinBox {
                        visible: modelData.inputType === "axis"

                        minValue: -1.0
                        maxValue: 1.0
                        value: modelData.axisValue

                        onValueModified: (newValue) => {
                            modelData.axisValue = newValue
                        }
                    }
                    Compact.ComboBox {
                        visible: modelData.inputType === "hat"

                        textRole: "text"
                        valueRole: "value"

                        model: [
                            {value: "center", text: "Center"},
                            {value: "north", text: "North"},
                            {value: "north-east", text: "North East"},
                            {value: "east", text: "East"},
                            {value: "south-east", text: "South East"},
                            {value: "south", text: "South"},
                            {value: "south-west", text: "South West"},
                            {value: "west", text: "West"},
                            {value: "north-west", text: "North West"}
                        ]

                        Component.onCompleted: () => {
                            currentIndex = Qt.binding(
                                () => indexOfValue(modelData.hatDirection)
                            )
                        }

                        onActivated: function () {
                            modelData.hatDirection = currentValue
                        }
                    }
                }
            }
        }

        // Key action
        DelegateChoice {
            roleValue: "key"

            DraggableAction {
                icon: bsi.icons.icon_keyboard
                label: "Keyboard"

                actionItem: RowLayout {
                    InputListener {
                        buttonLabel: Helpers.safeText(
                            modelData.key, "Record Input"
                        )
                        callback: (inputs) => { modelData.updateKey(inputs) }
                        multipleInputs: false
                        eventTypes: ["key"]
                    }

                    Compact.ButtonStateSelector {
                        isPressed: modelData.isPressed
                        onStateModified: (isPressed) => {
                            modelData.isPressed = isPressed
                        }
                    }
                }
            }
        }

        // Logical device action
        DelegateChoice {
            roleValue: "logical-device"

            DraggableAction {
                icon: bsi.icons.icon_logical_device
                label: "Logical device"

                actionItem: RowLayout {
                    LogicalDeviceSelector {
                        // The ordering is important, swapping it will result in the
                        // wrong item being displayed.
                        validTypes: ["axis", "button", "hat"]
                        logicalInputIdentifier: modelData.logicalInputIdentifier

                        onLogicalInputIdentifierChanged: () => {
                            modelData.logicalInputIdentifier = logicalInputIdentifier
                        }
                    }

                    LayoutHorizontalSpacer {}

                    // Show different components based on input
                    Compact.ButtonStateSelector {
                        visible: modelData.inputType === "button"

                        isPressed: modelData.isPressed
                        onStateModified: (isPressed) => {
                            modelData.isPressed = isPressed
                        }
                    }
                    RowLayout {
                        visible: modelData.inputType === "axis"

                        Compact.FloatSpinBox {
                            minValue: -1.0
                            maxValue: 1.0
                            value: modelData.axisValue

                            onValueModified: (newValue) => {
                                modelData.axisValue = newValue
                            }
                        }

                        ComboBox {
                            model: ["Absolute", "Relative"]

                            Component.onCompleted: () => {
                                currentIndex = find(
                                    Helpers.capitalize(modelData.axisMode)
                                )
                            }

                            onActivated: () => {
                                modelData.axisMode = currentValue
                            }
                        }
                    }
                    ComboBox {
                        visible: modelData.inputType === "hat"

                        textRole: "text"
                        valueRole: "value"

                        model: [
                            {value: "center", text: "Center"},
                            {value: "north", text: "North"},
                            {value: "north-east", text: "North East"},
                            {value: "east", text: "East"},
                            {value: "south-east", text: "South East"},
                            {value: "south", text: "South"},
                            {value: "south-west", text: "South West"},
                            {value: "west", text: "West"},
                            {value: "north-west", text: "North West"}
                        ]

                        currentIndex: indexOfValue(modelData.hatDirection)
                        Component.onCompleted: () => {
                            currentIndex = Qt.binding(
                                () => {return indexOfValue(modelData.hatDirection)}
                            )
                        }

                        onActivated: () => {
                            modelData.hatDirection = currentValue
                        }
                    }
                }
            }
        }


        // Mouse button
        DelegateChoice {
            roleValue: "mouse-button"

            DraggableAction {
                icon: bsi.icons.icon_mouse
                label: "Mouse Button"

                actionItem: RowLayout {
                    InputListener {
                        buttonLabel: Helpers.safeText(
                            modelData.button, "Record Input"
                        )
                        callback: (inputs) => { modelData.updateButton(inputs) }
                        multipleInputs: false
                        eventTypes: ["mouse"]
                    }

                    LayoutHorizontalSpacer {}

                    Compact.ButtonStateSelector {
                        isPressed: modelData.isPressed
                        onStateModified: (isPressed) => {
                            modelData.isPressed = isPressed
                        }
                    }
                }
            }
        }

        // Mouse motion
        DelegateChoice {
            roleValue: "mouse-motion"

            DraggableAction {
                icon: bsi.icons.icon_mouse
                label: "Mouse Motion"

                actionItem: RowLayout {
                    Label {
                        Layout.leftMargin: 5

                        text: "X-Axis"
                    }
                    JGSpinBox {
                        value: modelData.dx

                        onValueModified: () => { modelData.dx = value }
                    }

                    Label {
                        text: "Y-Axis"

                        leftPadding: 25
                    }
                    JGSpinBox {
                        value: modelData.dy

                        onValueModified: () => { modelData.dy = value }
                    }

                    LayoutHorizontalSpacer {}
                }
            }
        }

        // Pause action
        DelegateChoice {
            roleValue: "pause"

            DraggableAction {
                icon: bsi.icons.icon_pause
                label: "Pause"

                actionItem: RowLayout {
                    Compact.FloatSpinBox {
                        minValue: 0.0
                        maxValue: 10.0
                        value: modelData.duration

                        onValueModified: (newValue) => {
                            modelData.duration = newValue
                        }
                    }
                    Label {
                        text: "seconds"
                    }
                    LayoutHorizontalSpacer {}
                }
            }
        }

        // vJoy action
        DelegateChoice {
            roleValue: "vjoy"

            DraggableAction {
                icon: bsi.icons.icon_joystick
                label: "vJoy"

                actionItem: RowLayout {
                    VJoySelector {
                        Layout.alignment: Qt.AlignTop

                        validTypes: ["axis", "button", "hat"]

                        onSelectionChanged: (vjoyId, inputType, inputId) => {
                            modelData.vjoyId = vjoyId
                            modelData.inputType = inputType
                            modelData.inputId = inputId
                        }

                        Component.onCompleted: () => {
                            initialize(
                                modelData.vjoyId,
                                modelData.inputType,
                                modelData.inputId
                            )
                        }
                    }

                    LayoutHorizontalSpacer {}

                    // Show different components based on input.
                    Compact.ButtonStateSelector {
                        visible: modelData.inputType === "button"

                        isPressed: modelData.isPressed
                        onStateModified: (isPressed) => {
                            modelData.isPressed = isPressed
                        }
                    }
                    ColumnLayout {
                        visible: modelData.inputType === "axis"

                        Compact.FloatSpinBox {
                            minValue: -1.0
                            maxValue: 1.0
                            value: modelData.axisValue

                            onValueModified: (newValue) => {
                                modelData.axisValue = newValue
                            }
                        }

                        ComboBox {
                            model: ["Absolute", "Relative"]

                            Component.onCompleted: () => {
                                currentIndex = find(
                                    Helpers.capitalize(modelData.axisMode)
                                )
                            }

                            onActivated: () => {
                                modelData.axisMode = currentValue
                            }
                        }
                    }
                    ComboBox {
                        visible: modelData.inputType === "hat"

                        textRole: "text"
                        valueRole: "value"

                        model: [
                            {value: "center", text: "Center"},
                            {value: "north", text: "North"},
                            {value: "north-east", text: "North East"},
                            {value: "east", text: "East"},
                            {value: "south-east", text: "South East"},
                            {value: "south", text: "South"},
                            {value: "south-west", text: "South West"},
                            {value: "west", text: "West"},
                            {value: "north-west", text: "North West"}
                        ]

                        currentIndex: indexOfValue(modelData.hatDirection)
                        Component.onCompleted: () => {
                            currentIndex = Qt.binding(
                                () => {return indexOfValue(modelData.hatDirection)}
                            )
                        }

                        onActivated: () => {
                            modelData.hatDirection = currentValue
                        }
                    }
                }
            }
        }
    }


    // Predefined button that removes a given action
    component DeleteButton : IconButton {
        text: bsi.icons.remove
        font.pixelSize: 13

        onClicked: () => { _root.action.removeAction(index) }
    }

    // Displays an icon and also acts as the drag handle for the drag&drop
    // implementation
    component Icon : Label {
        property string iconName
        property var target

        property alias dragActive: _dragArea.drag.active

        text: bsi.icons.drag_handle + iconName

        font.pixelSize: 14

        MouseArea {
            id: _dragArea

            anchors.fill: parent

            drag.target: target
            drag.axis: Drag.YAxis

            // Create a visualization of the dragged item
            onPressed: () => {
                parent.parent.grabToImage(function(result) {
                    target.Drag.imageSource = result.url
                })
            }
        }
    }

    component ActionDrop : DropArea {
        property int targetIndex
        property string insertionMode: "append"

        height: 8

        Layout.fillWidth: true

        onDropped: (drop) => {
            drop.accept()
            _marker.opacity = 0.0
            _root.action.dropCallback(targetIndex, drop.text, insertionMode)
        }

        onEntered: () => {
            _marker.opacity = 1.0
        }
        onExited: () => {
            _marker.opacity = 0.0
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"

            Rectangle {
                id: _marker

                y: parent.y+5
                height: 10
                anchors.left: parent.left
                anchors.right: parent.right

                opacity: 0.0
                color: Style.accent
            }
        }
    }

    component DraggableAction : ColumnLayout {
        id: _draggableAction

        // Widget properties
        property string icon
        property string label
        property alias actionItem: _actionLoader.sourceComponent

        // Ensure entire width is taken up
        width: ListView.view ? ListView.view.width : 0
        // spacing: 0

        // Define drag&drop behavior
        Drag.dragType: Drag.Automatic
        Drag.active: _icon.dragActive
        Drag.supportedActions: Qt.MoveAction
        Drag.proposedAction: Qt.MoveAction
        Drag.mimeData: {
            "text/plain": index.toString()
        }
        Drag.onDragFinished: function (action) {
            // If the drop action ought to be ignored, reset the UI by calling
            // the InputConfiguration.qml reload function.
            if (action === Qt.IgnoreAction) {
                reload();
            }
        }

        // Widget content assembly
        RowLayout {
            id: _actionContent
            spacing: 4

            Icon {
                id: _icon

                Layout.alignment: Qt.AlignVCenter
                font.family: "bootstrap-icons"

                iconName: icon
                target: _draggableAction
            }

            Label {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: 150

                text: label
            }

            // Holds action specific UI elements
            Loader {
                id: _actionLoader

                Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                Layout.fillWidth: true
            }

            LayoutHorizontalSpacer {}

            DeleteButton {
                Layout.rightMargin: 10
            }
        }

        ActionDrop {
            Layout.bottomMargin: -4
            Layout.topMargin: -4

            targetIndex: index
        }
    }

}
