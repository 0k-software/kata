PLUGIN_VERSION := $(shell jq -r '.version' .claude-plugin/plugin.json 2>/dev/null)

# Install repo-managed git hooks from .git-hooks/ into the local .git/hooks/
# directory. Idempotent — safe to re-run; copies overwrite previous installs.
.PHONY: setup
setup: plugins
	@test -d .git || { echo "error: not a git working tree"; exit 1; }
	@for hook in .git-hooks/*; do \
		install -m 755 "$$hook" ".git/hooks/$$(basename $$hook)"; \
	done
	@echo "Installed git hooks from .git-hooks/"

# Ensure plugins enabled in .claude/settings.json are actually installed.
# extraKnownMarketplaces registers a marketplace, but plugins still need to
# be installed from it before their skills resolve.
.PHONY: plugins
plugins:
	@if command -v claude >/dev/null 2>&1; then \
		installed="$${CLAUDE_CONFIG_DIR:-$$HOME/.claude}/plugins/installed_plugins.json"; \
		if ! jq -e '.plugins["kata@0k-plugins"]' "$$installed" >/dev/null 2>&1; then \
			echo "Installing kata@0k-plugins..."; \
			claude plugin install kata@0k-plugins; \
		fi; \
	fi

.PHONY: release
release:
	@test -n "$(PLUGIN_VERSION)" || { echo "error: could not read version from .claude-plugin/plugin.json"; exit 1; }
	@git diff --quiet && git diff --cached --quiet \
		|| { echo "error: working tree is dirty — commit all changes first"; exit 1; }
	@git tag -a "v$(PLUGIN_VERSION)" -m "v$(PLUGIN_VERSION)" 2>/dev/null \
		|| { echo "error: tag v$(PLUGIN_VERSION) already exists"; exit 1; }
	@git push origin "v$(PLUGIN_VERSION)"
	@gh release create "v$(PLUGIN_VERSION)" \
		--title "v$(PLUGIN_VERSION)" \
		--generate-notes
	@echo "Released v$(PLUGIN_VERSION)"
