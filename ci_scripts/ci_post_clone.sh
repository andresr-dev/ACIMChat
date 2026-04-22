#!/bin/sh
# Disable Xcode macro fingerprint validation to allow third-party macros
defaults write com.apple.dt.Xcode IDESkipMacroFingerprintValidation -bool YES
