PLUGIN_NAME := kata
DEV_PLUGIN_NAME := kata-dev
DEV_MARKETPLACE_NAME := 0k-software-dev
DEV_MARKETPLACE_DIR := dev

.PHONY: all
all: install-plugin

# Installs from the local working copy under a separate
# `kata-dev@0k-software-dev` identity so it never clobbers a developer's
# published `kata@0k-software` install. End users get the published plugin via
# .claude/settings.json (extraKnownMarketplaces).
.PHONY: install-plugin
install-plugin:
	@claude plugin marketplace add "$(CURDIR)/$(DEV_MARKETPLACE_DIR)" 2>/dev/null \
		|| claude plugin marketplace update $(DEV_MARKETPLACE_NAME)
	@claude plugin install $(DEV_PLUGIN_NAME) 2>/dev/null \
		|| claude plugin update $(DEV_PLUGIN_NAME)
	@echo "Plugin $(DEV_PLUGIN_NAME) installed from local working copy"

PLUGIN_VERSION := $(shell jq -r '.version' .claude-plugin/plugin.json 2>/dev/null)

.PHONY: uninstall-plugin
uninstall-plugin:
	@claude plugin uninstall $(DEV_PLUGIN_NAME) 2>/dev/null || true
	@claude plugin marketplace remove $(DEV_MARKETPLACE_NAME) 2>/dev/null || true
	@echo "Plugin $(DEV_PLUGIN_NAME) uninstalled"

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
