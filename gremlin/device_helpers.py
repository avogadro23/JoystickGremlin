# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from enum import Enum
import logging
import math
import time
from typing import Tuple
import uuid

from PySide6 import QtCore

from gremlin import (
    common,
    event_handler,
    logical_device,
    mode_manager,
)
from gremlin.types import (
    HatDirection,
    InputType,
)
from vjoy.vjoy import VJoyProxy


class ModeMatch(Enum):

    """Defines how mode matching is performed for button release actions."""

    IgnoreMode = 1
    DifferentMode = 2
    MatchMode = 3


class ReleaseMode(Enum):

    """Defines how button release actions are triggered."""

    OnPress = 1
    OnRelease = 2


@dataclass
class ButtonReleaseEntry:

    callback : Callable[[], None]
    registration_mode : str
    mode_match : ModeMatch
    release_mode : ReleaseMode


@dataclass
class RegistryKey:

    device_uuid : uuid.UUID
    input_type: InputType
    input_id : int

    @classmethod
    def from_event(cls, event: event_handler.Event) -> RegistryKey:
        """Creates a RegistryKey from an event.

        Args:
            event: the event from which to create the key

        Returns:
            The corresponding RegistryKey instance
        """
        return cls(
            event.device_guid,
            event.event_type,
            event.identifier
        )

    def __hash__(self) -> int:
        return hash((self.device_uuid, self.input_type, self.input_id))


@common.SingletonDecorator
class ButtonReleaseActions(QtCore.QObject):

    """Ensures a desired action is run when a button is released."""

    def __init__(self) -> None:
        """Initializes the instance."""
        QtCore.QObject.__init__(self)

        self._registry = {}

        el = event_handler.EventListener()
        el.joystick_event.connect(self._input_event_cb)
        el.keyboard_event.connect(self._input_event_cb)
        el.virtual_event.connect(self._input_event_cb)

        mm = mode_manager.ModeManager()
        self._current_mode = mm.current.name
        mm.mode_changed.connect(self._mode_changed_cb)

    def register_callback(
        self,
        callback: Callable[[], None],
        physical_event: event_handler.Event,
        mode_match: ModeMatch=ModeMatch.IgnoreMode
    ) -> None:
        """Registers a callback with the system.

        Args:
            callback: the function to run when the corresponding button is
                released
            physical_event: the physical event of the button being pressed
            mode_match: defines how mode matching is performed for this entry
        """
        key = RegistryKey.from_event(physical_event)
        if key not in self._registry:
            self._registry[key] = []
        # When the release callback is executed can be controlled via the
        # mode_match argument.
        self._registry[key].append(
            ButtonReleaseEntry(
                callback,
                physical_event.mode,
                mode_match,
                ReleaseMode.OnRelease
            )
        )

    def register_vjoy_button_release(
        self,
        vjoy_input: Tuple[int, int],
        physical_event: event_handler.Event,
        activate_on_press: bool
    ) -> None:
        """Registers a physical and vjoy button pair for tracking.

        This method ensures that a vjoy button is pressed/released when the
        specified physical event occurs next. This is useful for cases where
        an action was triggered in a different mode or using a different
        condition.

        Args:
            vjoy_input: the vjoy button to release, represented as
                (vjoy_device_id, vjoy_button_id)
            physical_event: the button event when release should
                trigger the release of the vjoy button
            activate_on: button state on which to trigger the automatic
                release
        """
        key = RegistryKey.from_event(physical_event)
        if key not in self._registry:
            self._registry[key] = []

        # Only run the release callback if we're in a different mode to avoid
        # sending double release events.
        self._registry[key].append(
            ButtonReleaseEntry(
                lambda: self._release_vjoy_callback_prototype(vjoy_input),
                physical_event.mode,
                ModeMatch.DifferentMode,
                ReleaseMode.OnPress if activate_on_press else ReleaseMode.OnRelease
            )
        )

    def register_logical_button_release(
        self,
        logical_button_id: int,
        physical_event: event_handler.Event,
        activate_on_press: bool
    ) -> None:
        key = RegistryKey.from_event(physical_event)
        if key not in self._registry:
            self._registry[key] = []

        # Only run the release callback if we're in a different mode to avoid
        # sending double release events.
        self._registry[key].append(
            ButtonReleaseEntry(
                lambda: self._release_logical_device_callback_prototype(
                    logical_button_id
                ),
                physical_event.mode,
                ModeMatch.DifferentMode,
                ReleaseMode.OnPress if activate_on_press else ReleaseMode.OnRelease
            )
        )

    def reset(self) -> None:
        """Wipes the registry database."""
        self._registry = {}

    def _release_vjoy_callback_prototype(self, vjoy_input: Tuple[int, int]) -> None:
        """Prototype of a button release callback, used with lambdas.

        Args:
            vjoy_input: the vjoy input data to use in the release
        """
        vjoy = VJoyProxy()
        # Check if the button is valid otherwise we cause Gremlin to crash
        if vjoy_input[0] in vjoy.vjoy_devices \
                and vjoy[vjoy_input[0]].is_button_valid(vjoy_input[1]):
            vjoy[vjoy_input[0]].button(vjoy_input[1]).is_pressed = False
        else:
            logging.getLogger("system").warning(
                f"Attempted to use non existent button: " +
                f"vJoy {vjoy_input[0]:d} button {vjoy_input[1]:d}"
            )

    def _release_logical_device_callback_prototype(self, input_id: int) -> None:
        """Prototype of a button release callback, used with lambdas.

        Args:
            vjoy_input: the vjoy input data to use in the release
        """
        ld = logical_device.LogicalDevice()
        identifier = ld.Input.Identifier(InputType.JoystickButton, input_id)
        if ld.exists(identifier):
            ld[identifier].update(False)
        else:
            logging.getLogger("system").warning(
                f"Attempted to use non existent button: " +
                f"Logical Device button {input_id}."
            )

    def _input_event_cb(self, event: event_handler.Event) -> None:
        """Runs callbacks associated with the given event.

        Args:
            event: the event to process
        """
        key = RegistryKey.from_event(event)
        if key not in self._registry:
            return

        new_list = []
        for entry in self._registry.get(key, []):
            run_callback = True
            match entry.mode_match:
                case ModeMatch.IgnoreMode:
                    run_callback = True
                case ModeMatch.DifferentMode:
                    run_callback = self._current_mode != entry.registration_mode
                case ModeMatch.MatchMode:
                    run_callback = self._current_mode == entry.registration_mode

            if not run_callback:
                pass
            elif event.is_pressed == (entry.release_mode == ReleaseMode.OnPress):
                entry.callback()
            else:
                new_list.append(entry)
        self._registry[key] = new_list

    def _mode_changed_cb(self, mode: str) -> None:
        """Updates the current mode variable.

        Args:
            mode: name of the now active mode
        """
        self._current_mode = mode


class JoystickInputSignificant(metaclass=common.SingletonMetaclass):

    """Checks whether or not joystick inputs are significant."""

    def __init__(self) -> None:
        """Initializes the instance."""
        self._event_registry = {}
        self._mre_registry = {}
        self._time_registry = {}

    def should_process(self, event: event_handler.Event) -> bool:
        """Returns whether or not a particular event is significant enough to
        process.

        Args:
            event: the event to check for significance

        Returns:
            True if the event should be processed, False otherwise
        """
        self._mre_registry[event] = event

        match event.event_type:
            case InputType.JoystickAxis:
                return self._process_axis(event)
            case InputType.JoystickButton:
                return self._process_button(event)
            case InputType.JoystickHat:
                return self._process_hat(event)
            case _:
                logging.getLogger("system").warning(
                    "Event with unknown type received"
                )
                return False

    def last_event(self, event: event_handler.Event) -> event_handler.Event:
        """Returns the most recent event of this type.

        Args:
            event: the type of event for which to return the most recent one

        Returns:
            Latest event instance corresponding to the specified event
        """
        return self._mre_registry[event]

    def reset(self) -> None:
        """Resets the detector to a clean state for subsequent uses."""
        self._event_registry = {}
        self._mre_registry = {}
        self._time_registry = {}

    def _process_axis(self, event: event_handler.Event) -> bool:
        """Process an axis event.

        Args:
            event: the axis event to process

        Returns:
            True if it should be processed, False otherwise
        """
        if event in self._event_registry:
            # Reset everything if we have no recent data.
            if self._time_registry[event] + 5.0 < time.time():
                self._event_registry[event] = event
                self._time_registry[event] = time.time()
                return False
            # Update state.
            else:
                self._time_registry[event] = time.time()
                if abs(self._event_registry[event].value - event.value) > 0.33:
                    self._event_registry[event] = event
                    self._time_registry[event] = time.time()
                    return True
                else:
                    return False
        else:
            self._event_registry[event] = event
            self._time_registry[event] = time.time()
            return False

    def _process_button(self, event: event_handler.Event) -> bool:
        """Process a button event.

        Args:
            event: the button event to process

        Returns:
            True if it should be processed, False otherwise
        """
        return True

    def _process_hat(self, event: event_handler.Event) -> bool:
        """Process a hat event.

        Args:
            event: the hat event to process

        Returns:
            True if it should be processed, False otherwise
        """
        return event.value != HatDirection.Center


class AxisChangeSignificanceTracker:

    def __init__(
        self,
        initial_value: float,
        minimum_change: float,
        minimum_time_interval: float,
        record_crossings: bool
    ) -> None:
        self._last_time = time.monotonic_ns()
        self._last_value = initial_value
        self._minimum_change = minimum_change
        self._minimum_time_interval = minimum_time_interval * 1e9
        self._record_crossings = record_crossings

    def is_significant_change(self, new_value: float) -> bool:
        time_now = time.monotonic_ns()
        # Precompute values used to determine if a significant change is present.
        time_delta = time_now - self._last_time
        value_delta = abs(new_value - self._last_value)
        zero_crossed = (new_value > 0) != (self._last_value > 0)
        extrema_reached = (abs(self._last_value) != 1.0 and abs(new_value) == 1.0)

        if self._record_crossings and (zero_crossed or extrema_reached):
            self._last_time = time_now
            self._last_value = new_value
            return True

        if time_delta >= self._minimum_time_interval and \
                value_delta >= self._minimum_change:
            self._last_time = time_now
            self._last_value = new_value
            return True

        return False
