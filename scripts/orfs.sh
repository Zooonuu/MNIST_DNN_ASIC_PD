#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.."
    pwd
)"

ORFS_DOCKER_SHELL="/media/joo/eda-data/tools/OpenROAD-flow-scripts/flow/util/docker_shell"
DESIGN_CONFIG="/work/config/sky130hd/config.mk"

if [[ ! -x "$ORFS_DOCKER_SHELL" ]]; then
    echo "ERROR: ORFS docker_shell not found:"
    echo "  $ORFS_DOCKER_SHELL"
    exit 1
fi

cd "$PROJECT_ROOT"

exec "$ORFS_DOCKER_SHELL" \
    make \
    DESIGN_CONFIG="$DESIGN_CONFIG" \
    "$@"
