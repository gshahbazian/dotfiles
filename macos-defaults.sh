#!/usr/bin/env bash

# Dock "removal"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0.6
defaults write com.apple.dock autohide-time-modifier -float 0.5
defaults write com.apple.dock show-recents -bool false

# Better smoothing
defaults -currentHost write -g AppleFontSmoothing -int 0

# Key repeat
# The system has to be restarted for changes to take effect.
# All values copied from https://mac-key-repeat.zaymon.dev
defaults write -g InitialKeyRepeat -int 15
defaults write -g KeyRepeat -int 2
defaults write -g ApplePressAndHoldEnabled -bool false

# Finder
chflags nohidden ~/Library
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Text corrections
defaults write -g NSAutomaticCapitalizationEnabled -bool false
defaults write -g NSAutomaticDashSubstitutionEnabled -bool false
defaults write -g NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write -g NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
defaults write -g WebAutomaticSpellingCorrectionEnabled -bool false

defaults write -g NSDisableAutomaticTermination -bool true

# Zoom
defaults write com.apple.universalaccess closeViewScrollWheelToggle -bool true
defaults write com.apple.universalaccess HIDScrollZoomModifierMask -int 262144

# Window tiling
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# Personal UI preferences
defaults write -g AppleAccentColor -int 5
defaults write -g AppleAquaColorVariant -int 1
defaults write -g AppleIconAppearanceTintColor -string "Blue"
defaults write -g AppleScrollerPagingBehavior -bool true
defaults write -g com.apple.trackpad.forceClick -bool true
defaults write -g com.apple.trackpad.scaling -int 3
defaults -currentHost write -g com.apple.trackpad.scrollBehavior -int 2

# Restart affected apps
killall Dock
killall Finder
