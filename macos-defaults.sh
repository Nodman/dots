#!/bin/bash

# macOS System Defaults Configuration
# Sets sensible macOS defaults for development

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "Configuring macOS system defaults..."

# ===================================
# Dock Settings
# ===================================
log_info "Configuring Dock..."

# Automatically hide and show the Dock
defaults write com.apple.dock autohide -bool true

# Make Dock icons smaller
defaults write com.apple.dock "tilesize" -int "36"

# Remove the auto-hiding Dock delay
defaults write com.apple.dock "autohide-delay" -float "0"

# Remove the animation when hiding/showing the Dock
defaults write com.apple.dock "autohide-delay" -float "0.2"

# Animation effect when minimizing windows
defaults write com.apple.dock "mineffect" -string "scale"

# Don't show recent applications in Dock
defaults write com.apple.dock "show-recents" -bool "false"

killall Dock
# ===================================
# Finder Settings
# ===================================
log_info "Configuring Finder..."

# Show hidden files
defaults write com.apple.finder "AppleShowAllFiles" -bool "true"

# Show all file extensions
defaults write NSGlobalDomain "AppleShowAllExtensions" -bool "true"

# Show path bar
defaults write com.apple.finder "ShowPathbar" -bool "true"

# Keep folders on top when sorting by name
defaults write com.apple.finder "_FXSortFoldersFirst" -bool "true"

# When performing a search, search the current folder by default
defaults write com.apple.finder "FXDefaultSearchScope" -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder "FXEnableExtensionChangeWarning" -bool "false"

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `glyv`
defaults write com.apple.finder "FXPreferredViewStyle" -string "Nlsv"

# Show the ~/Library folder
sudo chflags nohidden ~/Library

# Show the /Volumes folder
sudo chflags nohidden /Volumes

killall Finder

# ===================================
# System Settings
# ===================================
log_info "Configuring System Settings..."

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

defaults write NSGlobalDomain "ApplePressAndHoldEnabled" -bool "false"

# Set a fast keyboard repeat rate
defaults write -g InitialKeyRepeat -int 12
defaults write -g KeyRepeat -int 2

# ===================================
# Trackpad Settings
# ===================================
log_info "Configuring Trackpad..."

# Enable tap to click for this user and for the login screen
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# Enable three finger drag
defaults write com.apple.AppleMultitouchTrackpad "TrackpadThreeFingerDrag" -bool "true"

# ===================================
# Screenshots
# ===================================
log_info "Configuring Screenshots..."

# Save screenshots to the Desktop/Screenshots
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Desktop/Screenshots"

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# ===================================
# Safari & WebKit
# ===================================
log_info "Configuring Safari..."

# Note: Safari preferences are sandboxed and may require manual configuration
log_info "Safari settings need to be configured manually:"
echo "  - Open Safari → Develop menu (if not visible: Safari → Preferences → Advanced → Show Develop menu)"
echo "  - For privacy: Safari → Preferences → Privacy → Prevent cross-site tracking"

# These Safari defaults may not work due to sandboxing, but we'll try:
defaults write com.apple.Safari IncludeDevelopMenu -bool true 2>/dev/null || log_warning "Safari developer menu setting failed (sandboxed)"
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true 2>/dev/null || true
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true 2>/dev/null || true

# ===================================
# Activity Monitor
# ===================================
log_info "Configuring Activity Monitor..."

# Show the main window when launching Activity Monitor
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true

# Visualize CPU usage in the Activity Monitor Dock icon
defaults write com.apple.ActivityMonitor IconType -int 5

# Show all processes in Activity Monitor
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# ===================================
# Other Settings
# ===================================
log_info "Configuring other settings..."

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# ===================================
# Apply Changes
# ===================================
log_info "Applying changes..."

# Kill affected applications
for app in "Dock" "Finder" "SystemUIServer" "Safari"; do
  killall "${app}" 2>/dev/null || true
done

log_success "macOS defaults configured successfully!"
log_info "Note: Some changes require a logout/restart to take effect."

echo ""
echo "Applied settings:"
echo "  ✅ Dock: Auto-hide, smaller icons, reduced animation"
echo "  ✅ Finder: Show hidden files, extensions, path/status bars"
echo "  ✅ System: Disabled quarantine, auto-correct, smart quotes"
echo "  ✅ Trackpad: Tap to click, three-finger drag"
echo "  ✅ Screenshots: Saved to Desktop/Screenshots as PNG"
echo "  ✅ Safari: Developer menu enabled"
echo "  ✅ Activity Monitor: Show all processes, CPU in dock"
echo ""
log_info "Please restart or log out for all changes to take effect."

