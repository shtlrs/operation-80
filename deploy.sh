#!/bin/sh
set -e

HASH=$(git rev-parse --short HEAD 2>/dev/null)
[ -z "$HASH" ] && HASH=dev
echo "const VERSION='$HASH';" > _version.js
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
