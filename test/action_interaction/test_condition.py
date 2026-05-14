# -*- coding: utf-8; -*-

# SPDX-License-Identifier: GPL-3.0-only

from __future__ import annotations

from pathlib import Path

from .conftest import JoystickGremlinBot
from .input_definitions import *


def test_basic(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "condition.xml")

    jgbot.press_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == False
    assert jgbot.button(OUT_BUTTON_2) == True
    jgbot.release_button(IN_BUTTON_1)

    jgbot.press_button(IN_BUTTON_2)
    jgbot.press_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    assert jgbot.button(OUT_BUTTON_2) == False
    jgbot.release_button(IN_BUTTON_1)


def test_release_during(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "condition.xml")

    jgbot.press_button(IN_BUTTON_2)
    jgbot.press_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    assert jgbot.button(OUT_BUTTON_2) == False
    jgbot.release_button(IN_BUTTON_2)
    jgbot.release_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    assert jgbot.button(OUT_BUTTON_2) == False

    jgbot.press_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    assert jgbot.button(OUT_BUTTON_2) == True
    jgbot.release_button(IN_BUTTON_1)
    assert jgbot.button(OUT_BUTTON_1) == True
    assert jgbot.button(OUT_BUTTON_2) == False


def test_current_input(jgbot: JoystickGremlinBot, profile_dir: Path) -> None:
    jgbot.load_profile(profile_dir / "condition.xml")

    jgbot.press_button(IN_BUTTON_3)
    jgbot.wait(0.01)
    assert jgbot.button(OUT_BUTTON_3) == True
    jgbot.release_button(IN_BUTTON_3)
    jgbot.wait(0.01)
    assert jgbot.button(OUT_BUTTON_3) == False
