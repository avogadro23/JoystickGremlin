# Joystick Gremlin

## Introduction

**Getting Help:** If you have issues running Gremlin or questions on how to
make certain things work, the best place to ask for help is in the
`#joystick-gremlin` channel on the [HOTAS Discord](https://discord.gg/hotas).

This is my fork or JG R15 to experiment with adding a few features through Github Copilot:
Namely, fixing the Virutal Device Sort order, adding copy and paste of actions, and adding the automapper for virtual device.

Joystick Gremlin is a program that allows the configuration of joystick like devices, similar to what CH Control Manager and Thrustmaster's T.A.R.G.E.T. do for their respectively supported joysticks. However, Joystick Gremlin works with any device be it from different manufacturers or custom devices that appear as a joystick to Windows. Joystick Gremlin uses the virtual joysticks provided by vJoy to map physical to virtual inputs and apply various other transformations such as response curves to analogue axes. In addition to customizing joysticks, Joystick Gremlin also provides powerful macro functionalities, a flexible mode system, scripting using Python, and many other features.

The main features are:

- Works with arbitrary joystick like devices
- User interface for common and some not so common configuration tasks
- Merging of multiple physical devices into a single virtual device
- Axis response curve and dead zone configuration
- Mapping of joystick inputs to keyboard and mouse inputs
- Powerful and flexible macro system
- Arbitrary number of modes with inheritance and customizable mode switching
- Conditional execution of configured actions
- Python scripting support for unlimited customization

Joystick Gremlin provides a graphical user interface which allows commonly performed tasks, such as input remapping, axis response curve setups, and macro recording to be performed easily. Functionality that is not accessible via the UI can be implemented through custom modules.

## Getting Started

For a list of dependencies and an overview of how to install and use Gremlin take a look at the [Manual](https://whitemagic.github.io/JoystickGremlin/).


## Contributing

If you want to contribute to Gremlin by implementing new features or fixing bugs, you will need a local development setup. The easiest way is described below.

### Development Setup

The easiest way to get all the required libraries installed for Gremlin development is via a virtual environment managed by [Poetry](https://python-poetry.org). Throughout this the assumption is that [VS Code](https://code.visualstudio.com/) is used and the appropriate Python plugins are installed.

### Installing Poetry

Abbreviated instructions from the [official documentation](https://python-poetry.org/docs/#installing-with-the-official-installer).

- Install a Gremlin compatible version of Python, such as 3.13.x
- Open a new Terminal / Powershell instance
- Run the command
  ```powershell
  (Invoke-WebRequest -Uri https://install.python-poetry.org -UseBasicParsing).Content | py -
  ```
- Add the poetry executable to your PATH setting
  ```powershell
  [Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\Users\Lionel\AppData\Roaming\Python\Scripts", "User")
  ```
- Launch a new Terminal / Powershell instance and check if poetry can be found by running
  ````powershell
  poetry --version
  ````
- Add the Poetry plugin (`zeshuaro.vscode-python-poetry`) to VS Code
- Create a virtual environment and install required packages by running the `Poetry install packages` command (`Ctrl + Shift + P`) in VS Code

- Restart VS Code for the new environment to be picked up
- Select the newly created Poetry virtual environment as the project's interpreter
