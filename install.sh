#!/usr/bin/env bash
# 把 ~/pi-agent-config 的可移植配置软链进 ~/.pi/agent/
# 已存在的文件先备份为 .bak-<timestamp>。auth.json 永远不动,各机自己登录。
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.pi/agent"
STAMP="$(date +%Y%m%dT%H%M%SZ)"

# 软链:name 进 $DEST/<name>
LINK_TOP=("skills" "agents" "AGENTS.md" "settings.json" "optimizer.json" "models.json")
# 软链:$SRC/npm/<name> 进 $DEST/npm/<name>(node_modules 仍各机本地)
LINK_NPM=("package.json" "package-lock.json")

backup() {
  local target="$1"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    mv "$target" "$target.bak-$STAMP"
    echo "backed up: $target -> $target.bak-$STAMP"
  fi
}

for name in "${LINK_TOP[@]}"; do
  backup "$DEST/$name"
  ln -sfn "$SRC/$name" "$DEST/$name"
  echo "linked: $DEST/$name"
done

mkdir -p "$DEST/npm"
for name in "${LINK_NPM[@]}"; do
  backup "$DEST/npm/$name"
  ln -sfn "$SRC/npm/$name" "$DEST/npm/$name"
  echo "linked: $DEST/npm/$name"
done

if [ -d "$DEST/npm/node_modules" ]; then
  echo "node_modules exists, skipping npm install"
else
  echo "running npm install..."
  (cd "$DEST/npm" && npm install)
fi

echo "done. remember: run 'pi' once on this machine to create local auth.json"
