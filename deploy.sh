#!/bin/sh
set -e

HASH=$(git rev-parse --short HEAD 2>/dev/null)
[ -z "$HASH" ] && HASH=dev
echo "Built version: $HASH"

ENV=$(printf "production\npreview\nother" | fzf --prompt="Deploy to: " --height=10 --border)
[ -z "$ENV" ] && echo "Cancelled." && exit 0

if [ "$ENV" = "production" ]; then
  BRANCH=main
elif [ "$ENV" = "preview" ]; then
  printf "Preview branch name: " > /dev/tty
  read BRANCH < /dev/tty
  [ -z "$BRANCH" ] && echo "Cancelled." && exit 0
else
  printf "Branch name: " > /dev/tty
  read BRANCH < /dev/tty
  [ -z "$BRANCH" ] && echo "Cancelled." && exit 0
fi

npx wrangler pages deploy . --project-name operation80 --branch "$BRANCH"
npx wrangler kv key put --namespace-id=862cd0c9c955470583098512e8c115c1 "app-version" "$HASH" --remote
echo "Version $HASH written to KV."
