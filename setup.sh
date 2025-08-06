#!/bin/bash

# macOS Setup Script
# Automates the setup process for a new Mac with all your tools and configurations

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

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log_info "Starting macOS setup from: $DOTFILES_DIR"
log_info "Setting up for user: $(whoami)"

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
  log_error "This script is designed for macOS only!"
  exit 1
fi

# Check for Xcode Command Line Tools
log_info "Checking for Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
  log_warning "Xcode Command Line Tools not found. Installing..."
  xcode-select --install
  log_info "Please follow the prompts to install Xcode Command Line Tools, then re-run this script"
  exit 1
else
  log_success "Xcode Command Line Tools are installed"
fi

# Install Homebrew if not present
log_info "Checking for Homebrew..."
if ! command -v brew &>/dev/null; then
  log_warning "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >>~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"

  log_success "Homebrew installed successfully"
else
  log_success "Homebrew is already installed"
fi

# Update Homebrew
log_info "Updating Homebrew..."
brew update

# Install packages from .Brewfile
log_info "Installing packages from .Brewfile..."
if [[ -f "$DOTFILES_DIR/.Brewfile" ]]; then
  cp "$DOTFILES_DIR/.Brewfile" "$HOME/Brewfile"
  brew bundle install --file="$HOME/Brewfile"
  rm "$HOME/Brewfile"  # Clean up temporary file
  log_success "All packages installed from .Brewfile"
else
  log_error ".Brewfile not found in $DOTFILES_DIR"
  exit 1
fi

# Function to create symlink with backup
create_symlink() {
  local source="$1"
  local target="$2"

  # Create target directory if it doesn't exist
  mkdir -p "$(dirname "$target")"

  # If target exists and is not a symlink, back it up
  if [[ -e "$target" && ! -L "$target" ]]; then
    log_warning "Backing up existing $target to $target.backup"
    mv "$target" "$target.backup"
  fi

  # Remove existing symlink if it exists
  if [[ -L "$target" ]]; then
    rm "$target"
  fi

  # Create new symlink
  ln -sf "$source" "$target"
  log_success "Linked $source -> $target"
}

# Create symlinks for dotfiles
log_info "Creating symlinks for configuration files..."

# Main config files
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
create_symlink "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"

# Config directories
create_symlink "$DOTFILES_DIR/.config/kitty" "$HOME/.config/kitty"
create_symlink "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"
create_symlink "$DOTFILES_DIR/.config/gh" "$HOME/.config/gh"
create_symlink "$DOTFILES_DIR/.hammerspoon" "$HOME/.hammerspoon"

# Local scripts
create_symlink "$DOTFILES_DIR/.local/scripts" "$HOME/.local/scripts"

# AppleScript files
create_symlink "$DOTFILES_DIR/applescript" "$HOME/applescript"

# Zsh plugins
create_symlink "$DOTFILES_DIR/.zsh" "$HOME/.zsh"

# Initialize and update submodules (zsh plugins)
log_info "Setting up zsh plugins via submodules..."

# Since .zsh is symlinked to dotfiles/.zsh, we need to update submodules in the dotfiles directory
if [[ -f "$DOTFILES_DIR/.gitmodules" ]]; then
  cd "$DOTFILES_DIR"
  git submodule init
  git submodule update
  log_success "Zsh plugin submodules updated"
else
  log_warning "No .gitmodules found, zsh plugins may need manual setup"
fi

# Return to original directory
cd ~

# Install Pure prompt
log_info "Installing Pure prompt..."
if ! brew list | grep -q "pure"; then
  brew install pure
  log_success "Pure prompt installed"
else
  log_success "Pure prompt already installed"
fi

# Set up fnm (Node.js version manager)
log_info "Setting up fnm..."
if command -v fnm &>/dev/null; then
  # Install latest LTS Node.js
  fnm install --lts
  fnm use lts-latest
  fnm default lts-latest
  log_success "Node.js LTS installed and set as default"
else
  log_warning "fnm not found, skipping Node.js setup"
fi

# Configure macOS system defaults
log_info "Configuring macOS system defaults..."
if [[ -f "$DOTFILES_DIR/macos-defaults.sh" ]]; then
  "$DOTFILES_DIR/macos-defaults.sh"
else
  log_warning "macos-defaults.sh not found, skipping macOS configuration"
fi

# Set zsh as default shell if it isn't already
if [[ "$SHELL" != *"zsh"* ]]; then
  log_info "Setting zsh as default shell..."
  chsh -s $(which zsh)
  log_success "Default shell changed to zsh"
fi

log_success "Setup completed successfully!"
log_info "Please restart your terminal or run: source ~/.zshrc"

echo ""
log_info "What was installed/configured:"
echo "  ✅ Homebrew + all packages from .Brewfile"
echo "  ✅ Zsh with custom plugins and Pure prompt"
echo "  ✅ Tmux configuration"
echo "  ✅ Git configuration"
echo "  ✅ GitHub CLI configuration"
echo "  ✅ Kitty terminal configuration"
echo "  ✅ Neovim configuration"
echo "  ✅ Hammerspoon configuration"
echo "  ✅ Local scripts"
echo "  ✅ AppleScript files"
echo "  ✅ Node.js (via fnm)"
echo "  ✅ macOS system preferences"
echo ""
log_info "Enjoy your new Mac setup! 🚀"

