#!/bin/bash
# Claude Code Agent Installer (Copy Version)
# Copies agents directly instead of using symlinks

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AGENTS_SOURCE_DIR="$SCRIPT_DIR/agents"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_AGENTS_DIR="$CLAUDE_DIR/agents"

echo "🤖 Claude Code Agent Installer (Copy Mode)"
echo "=========================================="
echo ""

# Create Claude directory if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "📁 Creating ~/.claude directory..."
    mkdir -p "$CLAUDE_DIR"
fi

# Check if agents directory exists
if [ -L "$CLAUDE_AGENTS_DIR" ]; then
    echo "🔗 Removing existing symlink..."
    rm "$CLAUDE_AGENTS_DIR"
fi

if [ -d "$CLAUDE_AGENTS_DIR" ]; then
    echo "📂 Existing agents directory found"
    EXISTING_COUNT=$(ls -1 "$CLAUDE_AGENTS_DIR"/*.md 2>/dev/null | wc -l)

    if [ "$EXISTING_COUNT" -gt 0 ]; then
        echo "   Found $EXISTING_COUNT existing agent(s)"
        echo ""
        read -p "   Backup existing agents? (y/n) " -n 1 -r
        echo

        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_DIR="$CLAUDE_AGENTS_DIR.backup.$(date +%Y%m%d_%H%M%S)"
            cp -r "$CLAUDE_AGENTS_DIR" "$BACKUP_DIR"
            echo "✅ Backed up to: $BACKUP_DIR"
        fi
    fi
else
    echo "📁 Creating ~/.claude/agents directory..."
    mkdir -p "$CLAUDE_AGENTS_DIR"
fi

# Copy all agents
echo ""
echo "📋 Copying agents from ai-config..."

if [ -d "$AGENTS_SOURCE_DIR" ]; then
    AGENT_COUNT=$(ls -1 "$AGENTS_SOURCE_DIR"/*.md 2>/dev/null | wc -l)

    if [ "$AGENT_COUNT" -gt 0 ]; then
        cp "$AGENTS_SOURCE_DIR"/*.md "$CLAUDE_AGENTS_DIR/"
        echo "✅ Copied $AGENT_COUNT agent(s)"
    else
        echo "⚠️  No agent files found in $AGENTS_SOURCE_DIR"
    fi
else
    echo "❌ Source directory not found: $AGENTS_SOURCE_DIR"
    exit 1
fi

echo ""
echo "📊 Current Agent Status:"
echo "========================"

INSTALLED_COUNT=$(ls -1 "$CLAUDE_AGENTS_DIR"/*.md 2>/dev/null | wc -l)
if [ "$INSTALLED_COUNT" -gt 0 ]; then
    echo "Installed Global Agents ($INSTALLED_COUNT):"
    ls -1 "$CLAUDE_AGENTS_DIR"/*.md 2>/dev/null | xargs -I {} basename {} .md | sed 's/^/  🤖 /'
else
    echo "No agents installed"
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "To use agents in Claude Code:"
echo "  • Type '/agents' to see all available agents"
echo "  • Agents are now available globally across all projects"
echo ""
echo "⚠️  Note: Since this uses copies instead of symlinks,"
echo "    you'll need to re-run this installer after adding new agents"
echo "    or modifying existing ones in ai-config."
echo ""
echo "To sync changes from ai-config:"
echo "  cd ~/Documents/projects/ai-config"
echo "  ./claude/install-agents-copy.sh"