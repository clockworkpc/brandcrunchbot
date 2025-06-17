#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$HOME/Development/brandcrunchbot"
SESSION=${1:-brandcrunch}

# Validate directory exists
if [ ! -d "$PROJECT_DIR" ]; then
  echo "Directory $PROJECT_DIR does not exist."
  exit 1
fi

cd "$PROJECT_DIR"

# Attach if session exists
if tmux has-session -t "$SESSION" 2>/dev/null; then
  exec tmux attach -t "$SESSION"
fi

# Start new session in PROJECT_DIR with window named DOCKER
tmux new-session -d -s "$SESSION" -n DOCKER -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION:DOCKER" 'docker compose up' C-m

# Window: LOGS
tmux new-window -t "$SESSION" -n LOGS -c "$PROJECT_DIR"
tmux send-keys -t "$SESSION:LOGS" 'tail -F log/development.log' C-m

# Window: DEV with vertical split (top: IDE, bottom: CLI)
tmux new-window -t "$SESSION" -n DEV -c "$PROJECT_DIR"
tmux split-window -v -t "$SESSION:DEV" -c "$PROJECT_DIR"

tmux select-pane -t "$SESSION:DEV.0" -T 'IDE'
tmux send-keys -t "$SESSION:DEV.0" 'nvim .' C-m

tmux select-pane -t "$SESSION:DEV.1" -T 'CLI'
tmux send-keys -t "$SESSION:DEV.1" 'bundle exec guard' C-m

# Go to DEV and attach
tmux select-window -t "$SESSION:DEV"
tmux attach -t "$SESSION"
