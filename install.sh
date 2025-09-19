#!/bin/bash
# AI Config Installer
# Sets up global configuration for Claude Code and other AI tools

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLAUDE_SETTINGS_DIR="$HOME/.claude"
CLAUDE_SETTINGS_FILE="$CLAUDE_SETTINGS_DIR/settings.json"

echo "🚀 AI Config Installer"
echo "====================="
echo ""

# Check for Python and pip
echo "📦 Checking dependencies..."
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is required but not installed."
    exit 1
fi

# Install Python dependencies
echo "📦 Installing Python dependencies..."
pip3 install --user -r "$SCRIPT_DIR/requirements.txt" > /dev/null 2>&1
echo "✅ Python dependencies installed"

# Make statusline.py executable
chmod +x "$SCRIPT_DIR/statusline.py"

# Configure Claude Code settings
echo ""
echo "🤖 Configuring Claude Code..."

# Create Claude settings directory if it doesn't exist
mkdir -p "$CLAUDE_SETTINGS_DIR"

# Check if settings file exists and has content
if [ -f "$CLAUDE_SETTINGS_FILE" ] && [ -s "$CLAUDE_SETTINGS_FILE" ]; then
    echo "📝 Updating existing Claude settings..."

    # Create a backup
    cp "$CLAUDE_SETTINGS_FILE" "$CLAUDE_SETTINGS_FILE.backup"

    # Update settings using Python to properly handle JSON
    python3 - <<EOF
import json
import sys

settings_file = "$CLAUDE_SETTINGS_FILE"
statusline_path = "$SCRIPT_DIR/statusline.py"

try:
    with open(settings_file, 'r') as f:
        settings = json.load(f)
except:
    settings = {}

# Update statusLine configuration
settings['statusLine'] = {
    'type': 'command',
    'command': statusline_path
}

with open(settings_file, 'w') as f:
    json.dump(settings, f, indent=2)

print(f"✅ Claude Code configured to use statusline at: {statusline_path}")
EOF
else
    echo "📝 Creating new Claude settings..."

    # Create new settings file
    cat > "$CLAUDE_SETTINGS_FILE" <<EOF
{
  "statusLine": {
    "type": "command",
    "command": "$SCRIPT_DIR/statusline.py"
  }
}
EOF
    echo "✅ Claude Code configured to use statusline at: $SCRIPT_DIR/statusline.py"
fi

# Install agents if the directory exists
if [ -d "$SCRIPT_DIR/claude/agents" ]; then
    echo ""
    echo "📦 Installing Claude Code agents..."
    "$SCRIPT_DIR/claude/install-agents.sh"
fi

echo ""
echo "🎉 Installation complete!"
echo ""
echo "📌 Status line features:"
echo "   • 📁 Current directory"
echo "   • 🌿 Git branch and status"
echo "   • ⬢ Node.js/npm versions"
echo "   • 🐍 Python version"
echo "   • 🦀 Rust version"
echo "   • 🤖 AI model name"
echo ""
echo "💡 The status line will be active in your next Claude Code session."
echo ""
echo "🔧 To customize the status line, edit: $SCRIPT_DIR/statusline.py"