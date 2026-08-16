#!/bin/sh
HASH=$(git rev-parse --short HEAD 2>/dev/null)
[ -z "$HASH" ] && HASH=dev
echo "const VERSION='$HASH';" > _version.js
echo "Built version: $HASH"
npx wrangler pages deploy .
