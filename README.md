# 🚀 Spooner's macOS Dotfiles

Automated setup for a new macOS system with all my development tools, configurations, and preferences.

## 📦 What's Included

### Development Tools
- **Homebrew** - Package manager with all my essential tools
- **Node.js** - Via fnm (Fast Node Manager)
- **Git** - With custom aliases and VS Code integration
- **GitHub CLI** - With custom configuration and aliases
- **Neovim** - Full configuration with plugins
- **VS Code** - With extensions automatically installed

### Terminal Setup
- **Zsh** - With custom configuration and plugins
- **Kitty** - Terminal emulator with full config
- **Tmux** - Terminal multiplexer setup
- **Pure Prompt** - Clean, minimal zsh prompt

### System Tools
- **Hammerspoon** - macOS automation and window management
- **Rectangle Pro** - Window management
- **FZF** - Fuzzy finder
- **Ripgrep** - Fast text search
- **Bat** - Enhanced cat with syntax highlighting
- **Custom Scripts** - Personal utility scripts in `~/.local/scripts`
- **AppleScript Files** - macOS automation scripts in `~/applescript`

### Zsh Plugins
- **zsh-autosuggestions** - Command completion
- **zsh-syntax-highlighting** - Syntax highlighting
- **zsh-vim-mode** - Vi/Vim mode in zsh
- **zsh-yarn-completions** - Yarn completion
- **wd** - Directory jumping

## 🛠 Installation

### Fresh macOS Setup
```bash
# Clone this repository with submodules
git clone --recurse-submodules https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles

# Run the setup script
cd ~/dotfiles
./setup.sh
```

### If You Already Cloned Without Submodules
```bash
cd ~/dotfiles
git submodule init
git submodule update
```

### What the Script Does
1. **Installs Xcode Command Line Tools** (if needed)
2. **Installs Homebrew** (if not present)
3. **Installs all packages** from `Brewfile`
4. **Creates symlinks** for all configuration files
5. **Initializes and updates git submodules** (zsh plugins)
6. **Sets up Pure prompt**
7. **Configures macOS defaults** (Dock, Finder, etc.)
8. **Sets zsh as default shell**

## 📁 File Structure

```
dotfiles/
├── setup.sh              # Main setup script
├── macos-defaults.sh     # macOS system preferences
├── Brewfile              # Homebrew packages and casks
├── .zshrc                # Zsh configuration
├── .tmux.conf            # Tmux configuration
├── .gitconfig            # Git configuration
├── .config/
│   ├── kitty/           # Kitty terminal config
│   ├── nvim/            # Neovim configuration
│   └── gh/              # GitHub CLI configuration
├── .hammerspoon/        # Hammerspoon config
├── .local/
│   └── scripts/         # Custom utility scripts
├── applescript/         # AppleScript automation files
└── .zsh/               # Zsh plugins
    ├── zsh-autosuggestions/
    ├── zsh-syntax-highlighting/
    ├── zsh-vim-mode/
    ├── zsh-yarn-completions/
    └── wd/
```

## 🍎 macOS System Preferences

The `macos-defaults.sh` script configures sensible macOS defaults:
- **Dock**: Auto-hide, smaller icons, reduced animations
- **Finder**: Show hidden files, extensions, path bars
- **System**: Disable quarantine dialog, auto-correct, smart quotes  
- **Trackpad**: Tap to click, three-finger drag
- **Screenshots**: Saved to Desktop/Screenshots as PNG
- **Safari**: Developer menu enabled
- **Activity Monitor**: Show all processes

### Run macOS defaults separately:
```bash
./macos-defaults.sh
```

## 🔧 Manual Steps After Setup

### 1. Terminal Setup
- Restart your terminal or run: `source ~/.zshrc`
- Set Kitty as your default terminal (if desired)

### 2. Git Configuration
Update your Git user info:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 3. SSH Keys
Generate SSH keys for GitHub:
```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

### 4. GitHub CLI Authentication
After setup, authenticate with GitHub:
```bash
gh auth login
```

### 5. macOS System Preferences
Some preferences might require manual setup:
- System Preferences → Security & Privacy → Privacy → Accessibility → Enable Hammerspoon
- System Preferences → Keyboard → Shortcuts (customize as needed)

## 🎨 Customization

### Adding New Packages
Add to `Brewfile`:
```ruby
# Homebrew formulae
brew "package-name"

# Casks (GUI applications)
cask "application-name"

# VS Code extensions
vscode "extension.name"
```

Then run: `brew bundle install`

### Modifying Configurations
All config files are symlinked, so edit them directly:
- Zsh: `~/.zshrc`
- Tmux: `~/.tmux.conf`
- Git: `~/.gitconfig`
- GitHub CLI: `~/.config/gh/`
- Neovim: `~/.config/nvim/`
- Kitty: `~/.config/kitty/`
- Scripts: `~/.local/scripts/`
- AppleScript: `~/applescript/`

## 🚨 Troubleshooting

### Script Permission Denied
```bash
chmod +x setup.sh
```

### Homebrew Issues
```bash
# Reinstall Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Zsh Plugins Not Loading
```bash
# Source zshrc again
source ~/.zshrc

# Check if plugins exist
ls ~/.zsh/
```

### Node.js Issues
```bash
# Reinstall Node.js with fnm
fnm install --lts
fnm use lts-latest
fnm default lts-latest
```

## 📋 Key Features

### Zsh Configuration Highlights
- **Pure prompt** with git integration
- **Vi mode** for vim-like editing
- **Auto-suggestions** and syntax highlighting
- **Custom aliases** for common tasks
- **FZF integration** for fuzzy finding

### Tmux Features
- **Custom prefix**: `Ctrl-q` instead of `Ctrl-b`
- **Mouse support** enabled
- **Kitty integration** for true color support
- **Vi-mode** key bindings

### macOS Defaults
- Auto-hide Dock
- Show hidden files in Finder
- Enable tap-to-click
- Screenshots saved to Desktop/Screenshots
- Disable app quarantine dialog

## 🔄 Managing Updates

### Updating Zsh Plugins (Submodules)
```bash
# Update all submodules to latest
git submodule update --remote

# Update specific plugin
git submodule update --remote .zsh/zsh-autosuggestions

# Commit the updates
git add .gitmodules .zsh/
git commit -m "Update zsh plugin submodules"
```

### Adding New Plugins
```bash
# Add new plugin as submodule
git submodule add https://github.com/user/plugin .zsh/plugin-name

# Update setup script if needed
```

## 🤝 Contributing

Feel free to fork and customize for your own setup!

## 📝 License

This project is open source and available under the [MIT License](LICENSE).

---

**"May the force be with you!"** 🌟