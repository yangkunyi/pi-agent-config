#!/usr/bin/env bash
# 把 ~/pi-agent-config/grok 软链进 ~/.grok/
# 已存在的文件先备份为 .bak-<timestamp>。auth.json 永远不动,各机自己登录。
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/grok"
DEST="$HOME/.grok"
STAMP="$(date +%Y%m%dT%H%M%SZ)"

# config.toml deliberately NOT linked: grok updates实体化 symlink, and model
# backend switching (grok-model fan/official) rewrites the local copy, so it
# must stay a machine-local regular file. Use grok/config.toml as template.
# fan-api.key likewise stays local (~/.grok/fan-api.key, chmod 600).
LINK=("skills" "agents" "AGENTS.md")

backup() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak-$STAMP"
    echo "backed up: $target -> $target.bak-$STAMP"
  fi
}

mkdir -p "$DEST"
for name in "${LINK[@]}"; do
  backup "$DEST/$name"
  ln -sfn "$SRC/$name" "$DEST/$name"
  echo "linked: $DEST/$name"
done

echo "done. remember: run 'grok' once on this machine to create local auth.json"
