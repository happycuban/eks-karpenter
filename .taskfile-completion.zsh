# Taskfile.yml completion for zsh
# Source this file or add it to your .zshrc

_task_completion() {
  local tasks
  tasks=($(task --list-all 2>/dev/null | grep -E '^\*' | awk '{print $2}' | sed 's/:$//' 2>/dev/null))
  
  if [ ${#tasks[@]} -gt 0 ]; then
    compadd "${tasks[@]}"
  fi
}

compdef _task_completion task