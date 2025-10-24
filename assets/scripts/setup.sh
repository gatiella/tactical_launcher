#!/bin/bash

# Tactical Launcher Setup Script
echo "Setting up Tactical Launcher environment..."

# Create necessary directories
mkdir -p ~/tactical/bin
mkdir -p ~/tactical/projects
mkdir -p ~/tactical/packages
mkdir -p ~/tactical/go/src
mkdir -p ~/tactical/go/bin
mkdir -p ~/tactical/go/pkg

# Set environment variables
export TACTICAL_HOME=~/tactical
export GOPATH=~/tactical/go
export PATH=$PATH:$TACTICAL_HOME/bin:$GOPATH/bin

echo "Environment setup complete!"
echo "TACTICAL_HOME: $TACTICAL_HOME"
echo "GOPATH: $GOPATH"
echo ""
echo "To install Go tools, use Termux:"
echo "  pkg install golang"
echo ""
echo "Example Go project structure:"
echo "  ~/tactical/go/src/myproject/main.go"