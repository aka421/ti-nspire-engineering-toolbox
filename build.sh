#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
LUNA="$ROOT/tools/Luna/luna"
DIST="$ROOT/dist"
TOOLBOX_BUNDLE="$DIST/engineering_toolbox.lua"
TOOLBOX_OUTPUT="$DIST/engineering_toolbox.tns"
WORKSPACE_BUNDLE="$DIST/engineering_workspaces.lua"
WORKSPACE_OUTPUT="$DIST/engineering_workspaces.tns"

if [[ ! -x "$LUNA" ]]; then
  echo "Luna is not built yet. Run ./setup-luna.sh first." >&2
  exit 1
fi

mkdir -p "$DIST"

cat \
  "$ROOT/src/libraries/workspace.lua" \
  "$ROOT/src/libraries/expression.lua" \
  "$ROOT/src/libraries/expression_workspace.lua" \
  "$ROOT/src/libraries/complex.lua" \
  "$ROOT/src/libraries/phasor.lua" \
  "$ROOT/src/libraries/vectors.lua" \
  "$ROOT/src/libraries/coordinates.lua" \
  "$ROOT/src/libraries/linear.lua" \
  "$ROOT/src/libraries/matrix.lua" \
  "$ROOT/src/ui/menu.lua" \
  "$ROOT/src/ui/calculator.lua" \
  "$ROOT/src/ui/result_scroll.lua" \
  "$ROOT/src/calculators/workspace_memory.lua" \
  "$ROOT/src/ui/history.lua" \
  "$ROOT/src/calculators/complex.lua" \
  "$ROOT/src/calculators/complex_polar.lua" \
  "$ROOT/src/calculators/circuits.lua" \
  "$ROOT/src/calculators/rlc.lua" \
  "$ROOT/src/calculators/transients.lua" \
  "$ROOT/src/calculators/linear_solvers.lua" \
  "$ROOT/src/calculators/linear_algebra.lua" \
  "$ROOT/src/calculators/electromagnetics.lua" \
  "$ROOT/src/calculators/waves.lua" \
  "$ROOT/src/calculators/transmission.lua" \
  "$ROOT/src/calculators/transmission_power.lua" \
  "$ROOT/src/calculators/coordinates.lua" \
  "$ROOT/src/calculators/mechanical.lua" \
  "$ROOT/src/calculators/dynamics.lua" \
  "$ROOT/src/calculators/vibrations.lua" \
  "$ROOT/src/calculators/thermodynamics.lua" \
  "$ROOT/src/main.lua" \
  "$ROOT/src/menu/complex_polar_extensions.lua" \
  "$ROOT/src/menu/transmission_extensions.lua" \
  "$ROOT/src/menu/equation_solver_extensions.lua" \
  "$ROOT/src/menu/linear_algebra_extensions.lua" \
  "$ROOT/src/menu/mechanical_extensions.lua" \
  "$ROOT/src/menu/thermodynamics_extensions.lua" \
  "$ROOT/src/menu/rlc_extensions.lua" \
  "$ROOT/src/menu/transient_formula_extensions.lua" \
  "$ROOT/src/menu/workspace_memory_extensions.lua" \
  > "$TOOLBOX_BUNDLE"

cat \
  "$ROOT/src/libraries/workspace.lua" \
  "$ROOT/src/libraries/expression.lua" \
  "$ROOT/src/libraries/expression_workspace.lua" \
  "$ROOT/src/libraries/complex.lua" \
  "$ROOT/src/libraries/topic_dependency.lua" \
  "$ROOT/src/ui/menu.lua" \
  "$ROOT/src/ui/calculator.lua" \
  "$ROOT/src/ui/result_scroll.lua" \
  "$ROOT/src/calculators/workspace_memory.lua" \
  "$ROOT/src/topics/series_rlc.lua" \
  "$ROOT/src/topics/transmission_lines.lua" \
  "$ROOT/src/topics/two_wire_line.lua" \
  "$ROOT/src/topics/rail_launcher.lua" \
  "$ROOT/src/topics/ece216_ws34.lua" \
  "$ROOT/src/topics/ece216_formula_core.lua" \
  "$ROOT/src/workspace_main.lua" \
  > "$WORKSPACE_BUNDLE"

"$LUNA" "$TOOLBOX_BUNDLE" "$TOOLBOX_OUTPUT"
"$LUNA" "$WORKSPACE_BUNDLE" "$WORKSPACE_OUTPUT"

echo "Built: dist/engineering_toolbox.tns"
echo "Built: dist/engineering_workspaces.tns"
