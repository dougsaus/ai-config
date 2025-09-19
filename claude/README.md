# Claude Code Configuration Management

This directory contains reusable Claude Code configurations and agents that can be used across all your projects.

## 📁 Directory Structure

```
claude/
├── agents/                 # Global reusable agents
│   ├── openai-agents-sdk.md
│   └── [your agents].md
├── install-agents.sh      # Agent installation script
└── README.md             # This file
```

## 🤖 Agent System

### What Are Agents?

Agents are specialized Claude Code subagents that can be invoked for specific tasks. They:
- Have their own instructions and personality
- Can use specific tools
- Can be project-specific or global
- Are invoked using `/agents` command in Claude Code

### Agent Priority System

1. **Project agents** (`.claude/agents/`) - Highest priority
2. **Global agents** (`~/.claude/agents/`) - Available everywhere

When names conflict, project agents override global ones.

### Agent File Format

Each agent is a markdown file with YAML frontmatter:

```markdown
---
name: agent-name
description: Brief description shown in /agents list
tools: Bash, Read, Write, Edit, MultiEdit, Grep, Glob
model: opus  # or sonnet, haiku
color: cyan  # optional UI color
---

# Agent Name

## Your Role
Detailed instructions for the agent...

## Your Capabilities
- What you can do
- Your specialized knowledge

## Examples
Specific examples of usage...
```

## 🔧 Installation

### Automatic Installation

Run from the ai-config root:
```bash
./install.sh
```

This will:
1. Install the status line
2. Set up agent symlinks
3. Configure global settings

### Manual Agent Installation

To install just the agents:
```bash
./claude/install-agents.sh
```

This creates a symlink from `~/.claude/agents` to this directory, making all agents globally available.

## 📝 Creating New Agents

1. Create a new `.md` file in `claude/agents/`
2. Add appropriate frontmatter
3. Write clear instructions
4. Test using `/agents` command in Claude Code

### Example: Codex Integration Agent

```markdown
---
name: codex-helper
description: Uses codex CLI for GPT-5 assistance
tools: Bash, Read, Write
model: opus
---

# Codex Helper

You help users by leveraging GPT-5 via the codex CLI...
```

## 🚀 Usage in Projects

### In Any Project

Once installed, your agents are available globally:
1. Start Claude Code in any project
2. Type `/agents` to see available agents
3. Select and use as needed

### Project-Specific Overrides

To override a global agent in a specific project:
1. Create `.claude/agents/` in the project
2. Add an agent with the same name
3. Project version takes precedence

## 🔄 Updating Agents

Since agents are symlinked:
1. Edit files directly in `ai-config/claude/agents/`
2. Changes are immediately available everywhere
3. Commit changes to ai-config repo for version control

## 💡 Best Practices

### DO:
- Keep agents focused on specific tasks
- Use descriptive names
- Document agent capabilities clearly
- Version control in ai-config repo
- Test agents before committing

### DON'T:
- Put sensitive information in agents
- Create overly broad agents
- Duplicate existing Claude Code functionality
- Forget to document usage examples

## 🛠️ Troubleshooting

### Agents Not Appearing

Check symlink:
```bash
ls -la ~/.claude/agents
```

Should point to: `~/Documents/projects/ai-config/claude/agents`

### Reinstall Agents

```bash
cd ~/Documents/projects/ai-config
./claude/install-agents.sh
```

### Remove Agent System

```bash
rm ~/.claude/agents  # Remove symlink
```

## 📚 Available Agents

Current agents in this repository:

| Agent | Description | Use Case |
|-------|-------------|----------|
| openai-agents-sdk | Expert in @openai/agents SDK with GPT-5 codex | SDK implementation and debugging |
| [Add more as created] | ... | ... |

## 🔗 Integration with Projects

The ai-config repository serves as your personal "configuration hub":

```
ai-config/                    # Configuration hub
├── statusline.py            # Global status line
├── claude/
│   └── agents/             # Global agents
└── install.sh              # Master installer

your-project/                # Any project
└── .claude/
    ├── settings.local.json  # Your project overrides
    └── agents/             # Project-specific agents (optional)
```

## 📖 Further Reading

- [Claude Code Documentation](https://docs.claude.com)
- [Subagent Documentation](https://docs.claude.com/en/docs/claude-code/sub-agents.md)
- Parent directory README for status line configuration