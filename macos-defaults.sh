#!/usr/bin/env bash

# Dock "removal"
defaults write com.apple.dock autohide-delay -float 1.0
defaults write com.apple.dock autohide-time-modifier -float 0.5

# Better smoothing
defaults -currentHost write -g AppleFontSmoothing -int 0

# Key repeat
# The system has to be restarted for changes to take effect.
# All values copied from https://mac-key-repeat.zaymon.dev
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
defaults write -g ApplePressAndHoldEnabled -bool false

# Misc
chflags nohidden ~/Library
defaults write -g NSDisableAutomaticTermination -bool true
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Restart affected apps
killall Dock
killall Finder
