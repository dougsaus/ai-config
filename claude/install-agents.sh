#!/bin/bash
# Claude Code Agent Installer
# Manages global agent installation via symlinks

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
AGENTS_SOURCE_DIR="$SCRIPT_DIR/agents"
CLAUDE_DIR="$HOME/.claude"
CLAUDE_AGENTS_DIR="$CLAUDE_DIR/agents"

echo "🤖 Claude Code Agent Installer"
echo "=============================="
echo ""

# Create Claude directory if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "📁 Creating ~/.claude directory..."
    mkdir -p "$CLAUDE_DIR"
fi

# Check if agents directory exists or is a symlink
if [ -L "$CLAUDE_AGENTS_DIR" ]; then
    echo "🔗 Existing symlink found at ~/.claude/agents"
    CURRENT_TARGET=$(readlink "$CLAUDE_AGENTS_DIR")
    echo "   Currently pointing to: $CURRENT_TARGET"

    if [ "$CURRENT_TARGET" = "$AGENTS_SOURCE_DIR" ]; then
        echo "✅ Symlink already correctly configured!"
    else
        echo "⚠️  Symlink points to different location"
        read -p "   Update symlink to ai-config/claude/agents? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm "$CLAUDE_AGENTS_DIR"
            ln -s "$AGENTS_SOURCE_DIR" "$CLAUDE_AGENTS_DIR"
            echo "✅ Symlink updated!"
        fi
    fi
elif [ -d "$CLAUDE_AGENTS_DIR" ]; then
    echo "📂 Existing agents directory found at ~/.claude/agents"
    echo "   This contains actual files, not a symlink"

    # List existing agents
    EXISTING_AGENTS=$(ls -1 "$CLAUDE_AGENTS_DIR" 2>/dev/null | wc -l)
    if [ "$EXISTING_AGENTS" -gt 0 ]; then
        echo "   Found $EXISTING_AGENTS existing agent(s):"
        ls -1 "$CLAUDE_AGENTS_DIR" | sed 's/^/     - /'
    fi

    echo ""
    echo "Options:"
    echo "  1) Backup existing agents and create symlink"
    echo "  2) Merge existing agents into ai-config and create symlink"
    echo "  3) Keep existing setup (no changes)"

    read -p "Choose option (1-3): " -n 1 -r
    echo

    case $REPLY in
        1)
            BACKUP_DIR="$CLAUDE_AGENTS_DIR.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$CLAUDE_AGENTS_DIR" "$BACKUP_DIR"
            ln -s "$AGENTS_SOURCE_DIR" "$CLAUDE_AGENTS_DIR"
            echo "✅ Backed up to: $BACKUP_DIR"
            echo "✅ Symlink created!"
            ;;
        2)
            echo "📋 Merging agents..."
            cp -n "$CLAUDE_AGENTS_DIR"/*.md "$AGENTS_SOURCE_DIR/" 2>/dev/null || true
            BACKUP_DIR="$CLAUDE_AGENTS_DIR.backup.$(date +%Y%m%d_%H%M%S)"
            mv "$CLAUDE_AGENTS_DIR" "$BACKUP_DIR"
            ln -s "$AGENTS_SOURCE_DIR" "$CLAUDE_AGENTS_DIR"
            echo "✅ Agents merged into ai-config"
            echo "✅ Original backed up to: $BACKUP_DIR"
            echo "✅ Symlink created!"
            ;;
        3)
            echo "ℹ️  No changes made"
            ;;
    esac
else
    echo "🔗 Creating symlink: ~/.claude/agents -> ai-config/claude/agents"
    ln -s "$AGENTS_SOURCE_DIR" "$CLAUDE_AGENTS_DIR"
    echo "✅ Symlink created!"
fi

echo ""
echo "📊 Current Agent Status:"
echo "========================"

if [ -L "$CLAUDE_AGENTS_DIR" ]; then
    TARGET=$(readlink "$CLAUDE_AGENTS_DIR")
    echo "~/.claude/agents -> $TARGET"
    echo ""

    if [ -d "$TARGET" ]; then
        AGENT_COUNT=$(ls -1 "$TARGET"/*.md 2>/dev/null | wc -l)
        if [ "$AGENT_COUNT" -gt 0 ]; then
            echo "Available Global Agents ($AGENT_COUNT):"
            ls -1 "$TARGET"/*.md 2>/dev/null | xargs -I {} basename {} .md | sed 's/^/  🤖 /'
        else
            echo "No agents found in source directory"
            echo "Add .md files to: $AGENTS_SOURCE_DIR"
        fi
    fi
elif [ -d "$CLAUDE_AGENTS_DIR" ]; then
    AGENT_COUNT=$(ls -1 "$CLAUDE_AGENTS_DIR"/*.md 2>/dev/null | wc -l)
    echo "~/.claude/agents (directory with $AGENT_COUNT agents)"
fi

echo ""
echo "✨ Installation complete!"
echo ""
echo "To use agents in Claude Code:"
echo "  • Type '/agents' to see all available agents"
echo "  • Agents are now available globally across all projects"
echo ""
echo "To add new agents:"
echo "  • Create .md files in: $AGENTS_SOURCE_DIR"
echo "  • They'll be immediately available via the symlink"