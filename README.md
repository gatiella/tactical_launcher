# Tactical Launcher

A terminal-based Android launcher with shell access and development capabilities.

## Features

- ✅ Full terminal emulator interface
- ✅ Shell command execution
- ✅ Launch Android apps via terminal commands
- ✅ Package management system
- ✅ Go programming support
- ✅ File system navigation
- ✅ Multiple color themes (Matrix Green, Cyber Cyan, Alert Red, Warning Yellow)
- ✅ System monitoring
- ✅ Customizable settings

## Installation

1. Clone this repository
2. Run `flutter pub get`
3. Build and install: `flutter build apk`
4. Install the APK on your Android device

## Usage

### Basic Commands
```bash
help                    # Show all available commands
apps                    # List all installed apps
search chrome          # Search for specific apps
open chrome            # Launch app by name
open 0                 # Launch app by number
status                 # Show system status
clear                  # Clear terminal
```

### File System Commands
```bash
pwd                    # Print working directory
ls                     # List directory contents
cd /path/to/dir       # Change directory
cat file.txt          # Display file contents
```

### Package Management
```bash
pkg list              # List installed packages
pkg install <name>    # Install a package
pkg remove <name>     # Remove a package
```

### Go Development
```bash
go setup              # Setup Go environment
go run main.go        # Run a Go file
go build main.go      # Build a Go executable
go version            # Check Go version
```

## Requirements

- Flutter SDK >=3.0.0
- Android SDK 21+
- For Go development: Termux with golang package

## Project Structure