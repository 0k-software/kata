#!/bin/bash
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

make setup
