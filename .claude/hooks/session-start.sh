#!/bin/bash
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

make setup

# Marketplace is registered via extraKnownMarketplaces in .claude/settings.json,
# but that only makes Claude Code aware of it — the plugin still has to be
# installed from it before its /kata:* skills resolve.
if command -v claude >/dev/null 2>&1; then
    installed_file="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/plugins/installed_plugins.json"
    if ! jq -e '.plugins["kata@0k-plugins"]' "$installed_file" >/dev/null 2>&1; then
        echo "Installing kata@0k-plugins..."
        claude plugin install kata@0k-plugins
    fi
fi
