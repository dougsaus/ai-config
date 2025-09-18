#!/usr/bin/env python3
"""
Claude Code Status Line
A customizable status line for Claude Code sessions
"""

import json
import sys
import subprocess
from pathlib import Path
from typing import Optional, Tuple, Dict
from rich.console import Console
from rich.text import Text

class StatusLine:
    """Main status line class for Claude Code"""

    def __init__(self):
        self.console = Console(stderr=False, force_terminal=True, legacy_windows=False, width=160)

    def get_git_info(self, directory: Path) -> Tuple[bool, str, Dict]:
        """Returns (is_git_repo, location, status_counts)"""
        try:
            # Get git directory and check if inside work tree
            result = subprocess.run(
                ["git", "-C", str(directory), "rev-parse", "--git-dir", "--is-inside-work-tree"],
                capture_output=True,
                text=True
            )
            if result.returncode != 0:
                return False, "", {}

            lines = result.stdout.strip().split("\n")
            git_dir = Path(lines[0]) if lines else Path(".git")
            if not git_dir.is_absolute():
                git_dir = directory / git_dir

            # Get current branch or detached state
            result = subprocess.run(
                ["git", "-C", str(directory), "branch", "--show-current"],
                capture_output=True,
                text=True
            )
            branch = result.stdout.strip()

            # If no branch, check if detached and get short hash
            if not branch:
                result = subprocess.run(
                    ["git", "-C", str(directory), "rev-parse", "--short", "HEAD"],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    branch = f"@{result.stdout.strip()}"
                else:
                    branch = "detached"

            # Check for git operations
            operation = ""
            step = total_steps = 0

            # Check for rebase-merge
            rebase_merge_dir = git_dir / "rebase-merge"
            if rebase_merge_dir.exists():
                # Read step numbers
                msgnum_file = rebase_merge_dir / "msgnum"
                end_file = rebase_merge_dir / "end"
                if msgnum_file.exists() and end_file.exists():
                    step = int(msgnum_file.read_text().strip())
                    total_steps = int(end_file.read_text().strip())

                # Check if interactive
                if (rebase_merge_dir / "interactive").exists():
                    operation = "rebase-i"
                else:
                    operation = "rebase-m"

            # Check for rebase-apply
            elif (git_dir / "rebase-apply").exists():
                rebase_apply_dir = git_dir / "rebase-apply"
                next_file = rebase_apply_dir / "next"
                last_file = rebase_apply_dir / "last"
                if next_file.exists() and last_file.exists():
                    step = int(next_file.read_text().strip())
                    total_steps = int(last_file.read_text().strip())

                if (rebase_apply_dir / "rebasing").exists():
                    operation = "rebase"
                elif (rebase_apply_dir / "applying").exists():
                    operation = "am"
                else:
                    operation = "am/rebase"

            # Check for other operations
            elif (git_dir / "MERGE_HEAD").exists():
                operation = "merge"
            elif (git_dir / "CHERRY_PICK_HEAD").exists():
                operation = "cherry-pick"
            elif (git_dir / "REVERT_HEAD").exists():
                operation = "revert"
            elif (git_dir / "BISECT_LOG").exists():
                operation = "bisect"

            # Get git status porcelain
            result = subprocess.run(
                ["git", "-C", str(directory), "--no-optional-locks", "status", "--porcelain"],
                capture_output=True,
                text=True
            )
            stat_lines = result.stdout.splitlines() if result.returncode == 0 else []

            # Count different file states
            conflicted = sum(1 for line in stat_lines if line.startswith("UU"))
            staged = sum(1 for line in stat_lines if line[0] in "ADMR")
            dirty = sum(1 for line in stat_lines if line[1] in "ADMR")
            untracked = sum(1 for line in stat_lines if line.startswith("??"))

            # Get stash count
            result = subprocess.run(
                ["git", "-C", str(directory), "stash", "list"],
                capture_output=True,
                text=True
            )
            stash = len(result.stdout.splitlines()) if result.returncode == 0 else 0

            # Get ahead/behind counts
            ahead = behind = 0
            result = subprocess.run(
                ["git", "-C", str(directory), "rev-list", "--count", "--left-right", "@{u}...HEAD"],
                capture_output=True,
                text=True
            )
            if result.returncode == 0 and result.stdout.strip():
                counts = result.stdout.strip().split("\t")
                if len(counts) == 2:
                    behind = int(counts[0]) if counts[0] else 0
                    ahead = int(counts[1]) if counts[1] else 0

            return True, branch, {
                "conflicted": conflicted,
                "staged": staged,
                "dirty": dirty,
                "untracked": untracked,
                "stash": stash,
                "ahead": ahead,
                "behind": behind,
                "operation": operation,
                "step": step,
                "total_steps": total_steps
            }
        except Exception:
            return False, "", {}

    def get_language_info(self, directory: Path) -> Dict[str, str]:
        """Detect and return language/framework information"""
        info = {}

        # Node.js detection
        if (directory / "package.json").exists():
            try:
                node_version = subprocess.run(
                    ["node", "--version"],
                    capture_output=True,
                    text=True
                ).stdout.strip()
                info["node"] = node_version

                npm_version = subprocess.run(
                    ["npm", "--version"],
                    capture_output=True,
                    text=True
                ).stdout.strip()
                info["npm"] = f"npm@{npm_version}"
            except:
                pass

        # Python detection
        if (directory / "requirements.txt").exists() or (directory / "pyproject.toml").exists():
            try:
                python_version = subprocess.run(
                    ["python3", "--version"],
                    capture_output=True,
                    text=True
                ).stdout.strip().replace("Python ", "")
                info["python"] = f"py{python_version}"
            except:
                pass

        # Rust detection
        if (directory / "Cargo.toml").exists():
            try:
                rust_version = subprocess.run(
                    ["rustc", "--version"],
                    capture_output=True,
                    text=True
                ).stdout.strip().split()[1]
                info["rust"] = f"🦀{rust_version}"
            except:
                pass

        return info

    def format_cost(self, cost: Optional[float]) -> str:
        """Format cost as $X.XX"""
        if cost is None or cost == 0:
            return "$0.00"
        return f"${cost:.2f}"

    def build_status_line(self, data: Dict) -> Text:
        """Build the complete status line"""
        # Extract data with Claude Code's JSON structure
        current_dir = Path(data.get("cwd") or data.get("workspace", {}).get("current_dir", "."))
        model_name = data.get("model", {}).get("display_name", "unknown")

        # Claude Code doesn't provide cost in the status line JSON, so we'll skip it
        # unless it's provided in a custom field
        session_cost = data.get("cost", {}).get("total_cost_usd", 0) if "cost" in data else None

        # Prepare display values
        short_path = current_dir.name

        # Build status line
        status = Text()

        # Directory
        status.append("📁 ", style="cyan")
        status.append(short_path, style="cyan")
        status.append(" ")

        # Git info
        is_git, location, git_status = self.get_git_info(current_dir)
        if is_git:
            status.append("🌿 ", style="yellow")

            # Branch or detached HEAD
            if location.startswith("@"):
                status.append(location, style="green")
            else:
                status.append(location, style="yellow")

            # Git operation
            if git_status.get("operation"):
                status.append(f" {git_status['operation']}", style="red")
                if git_status.get("step") and git_status.get("total_steps"):
                    status.append(f" {git_status['step']}/{git_status['total_steps']}", style="red")

            # Git status indicators
            indicators = []
            if git_status.get("behind", 0) > 0:
                indicators.append(("⇣" + str(git_status["behind"]), "cyan"))
            if git_status.get("ahead", 0) > 0:
                indicators.append(("⇡" + str(git_status["ahead"]), "cyan"))
            if git_status.get("stash", 0) > 0:
                indicators.append(("*" + str(git_status["stash"]), "yellow"))
            if git_status.get("conflicted", 0) > 0:
                indicators.append(("~" + str(git_status["conflicted"]), "red"))
            if git_status.get("staged", 0) > 0:
                indicators.append(("+" + str(git_status["staged"]), "green"))
            if git_status.get("dirty", 0) > 0:
                indicators.append(("!" + str(git_status["dirty"]), "red"))
            if git_status.get("untracked", 0) > 0:
                indicators.append(("?" + str(git_status["untracked"]), "blue"))

            for text, style in indicators:
                status.append(" ")
                status.append(text, style=style)

            status.append(" ")

        # Language/framework info
        lang_info = self.get_language_info(current_dir)
        if "node" in lang_info:
            status.append("⬢ ", style="green")
            status.append(lang_info["node"], style="green")
            status.append(" ")
            if "npm" in lang_info:
                status.append("📦 ", style="blue")
                status.append(lang_info["npm"], style="blue")
                status.append(" ")

        if "python" in lang_info:
            status.append("🐍 ", style="yellow")
            status.append(lang_info["python"], style="yellow")
            status.append(" ")

        if "rust" in lang_info:
            status.append(lang_info["rust"], style="orange1")
            status.append(" ")

        # Model
        status.append("🤖 ", style="magenta")
        status.append(model_name, style="magenta")

        # Cost (if available)
        if session_cost is not None:
            status.append(" ")
            status.append("💰 ", style="green")
            status.append(self.format_cost(session_cost), style="green")

        return status

    def render(self, data: Dict):
        """Render the status line to console"""
        status = self.build_status_line(data)
        self.console.print(status, end="")


def main():
    """Main entry point"""
    statusline = StatusLine()

    # Read JSON from stdin if piped, otherwise use defaults
    if sys.stdin.isatty():
        # Not piped, use current directory for testing
        data = {
            "cwd": str(Path.cwd()),
            "model": {
                "display_name": "Claude"
            }
        }
    else:
        # Read JSON from stdin
        try:
            data = json.load(sys.stdin)
        except json.JSONDecodeError:
            # Fallback for invalid JSON
            data = {
                "cwd": str(Path.cwd()),
                "model": {
                    "display_name": "Claude"
                }
            }

    statusline.render(data)


if __name__ == "__main__":
    main()