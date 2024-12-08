# How to install linux on windows with WSL
- [Prerequisites](#prerequisites)

- [Install WSL command](#install-wsl-command)

- [Set up your Linux user info](#set-up-your-linux-user-info)

- [Set up and best practices](#set-up-and-best-practices)

- [Documentation](https://learn.microsoft.com/en-us/windows/wsl/install)

## Prerequisites
You must be running Windows 10 version 2004 and higher (Build 19041 and higher) or Windows 11 to use the commands below. If you are on earlier versions please see [the manual install page](https://learn.microsoft.com/en-us/windows/wsl/install-manual)

## Install WSL command
You can now install everything you need to run WSL with a single command. Open PowerShell or Windows Command Prompt in administrator mode by right-clicking and selecting "Run as administrator", enter the wsl --install command, then restart your machine.
```powershell
wsl --install
```
## Set up your Linux user info
Once you have installed WSL, you will need to create a user account and password for your newly installed Linux distribution. See the [Best practices for setting up a WSL development environment](https://learn.microsoft.com/en-us/windows/wsl/setup/environment#set-up-your-linux-username-and-password) guide to learn more.

## Set up and best practices
We recommend following our [Best practices for setting up a WSL development environment](https://learn.microsoft.com/en-us/windows/wsl/setup/environment) guide for a step-by-step walk-through of how to set up a user name and password for your installed Linux distribution(s), using basic WSL commands, installing and customizing Windows Terminal, set up for Git version control, code editing and debugging using the VS Code remote server, good practices for file storage, setting up a database, mounting an external drive, setting up GPU acceleration, and more.