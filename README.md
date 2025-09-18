# AI Config

Personal configuration and tools for AI-powered development environments.

## Features

### Claude Code Status Line
A rich, informative status line for Claude Code sessions showing:
- 📁 Current directory
- 🌿 Git branch and status indicators
- ⬢ Node.js/npm versions (when in Node projects)
- 🐍 Python version (when in Python projects)
- 🦀 Rust version (when in Rust projects)
- 🤖 Current AI model
- 💰 Session cost (when available)

#### Git Status Indicators
- `⇣N` - Behind upstream by N commits
- `⇡N` - Ahead of upstream by N commits
- `*N` - N stashed changes
- `~N` - N merge conflicts
- `+N` - N staged files
- `!N` - N modified files
- `?N` - N untracked files

## Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ai-config.git ~/Documents/projects/ai-config

# Run the installer
cd ~/Documents/projects/ai-config
./install.sh
```

The installer will:
1. Install required Python dependencies
2. Configure Claude Code to use the global status line
3. Create backup of existing settings if present

## Customization

### Status Line
Edit `statusline.py` to customize the status line appearance and features.

The status line class is modular and can be extended with:
- Additional language/framework detection
- Custom git status formatting
- Additional project information
- Custom color schemes

### Adding New Languages
To add detection for a new language/framework, edit the `get_language_info` method in `statusline.py`.

## Directory Structure

```
ai-config/
├── statusline.py       # Main status line script
├── requirements.txt    # Python dependencies
├── install.sh         # Installation script
└── README.md          # This file
```

## Future Plans

- [ ] Additional AI tool configurations
- [ ] Custom prompt templates
- [ ] Project-specific configurations
- [ ] Status line themes
- [ ] Performance metrics
- [ ] Token usage tracking

## Contributing

This is a personal configuration repository, but feel free to fork and customize for your own use!

## License

MIT