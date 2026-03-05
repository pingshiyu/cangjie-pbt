#!/usr/bin/env bash
# Profile the project binary with system profilers.
# Usage: ./scripts/profile.sh [--build-only] [--debug] [-- perf args...]
#   --build-only   only build, print binary path (for manual profiling)
#   --debug        use debug build (target/debug/bin/main)
#   --             pass remaining args to the binary
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$ROOT_DIR"

TARGET_DIR="${TARGET_DIR:-target}"
BUILD_MODE="release"
BINARY_NAME="${BINARY_NAME:-main}"
EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --build-only) BUILD_ONLY=1; shift ;;
    --debug)      BUILD_MODE="debug"; shift ;;
    --)           shift; EXTRA_ARGS=("$@"); break ;;
    *)            shift ;;
  esac
done

BIN_DIR="$TARGET_DIR/$BUILD_MODE/bin"
BINARY="$BIN_DIR/$BINARY_NAME"
[[ "$(uname -s)" == "MINGW"* || "$(uname -s)" == "MSYS"* || -n "$WINDIR" ]] && BINARY="${BINARY}.exe"

# Build
if [[ "$BUILD_MODE" == "debug" ]]; then
  cjpm build -g
else
  cjpm build
fi

if [[ ! -f "$BINARY" ]]; then
  echo "Binary not found: $BINARY" >&2
  echo "Build with: cjpm build" >&2
  exit 1
fi

if [[ -n "$BUILD_ONLY" ]]; then
  echo "$BINARY"
  exit 0
fi

# Run under profiler
PROFILE_DIR="${PROFILE_DIR:-$ROOT_DIR/profile}"
mkdir -p "$PROFILE_DIR"

case "$(uname -s)" in
  Linux*)
    PERF_DATA="$PROFILE_DIR/perf.data"
    if perf record -o "$PERF_DATA" -g --call-graph=dwarf true 2>/dev/null; then
      echo "Profiling with perf (output: $PERF_DATA) ..."
      perf record -o "$PERF_DATA" -g --call-graph=dwarf "$BINARY" "${EXTRA_ARGS[@]}"
      echo "Done. View with: perf report -i $PERF_DATA"
    else
      echo "perf is not available for this kernel (common on WSL2). Running binary without perf."
      echo "For CPU profiling, use in-process profiling: std.runtime.startCPUProfiling() / stopCPUProfiling(Path(\"cpu.prof\"))."
      echo "To install perf on native Linux: sudo apt install linux-tools-generic linux-tools-\$(uname -r)"
      exec "$BINARY" "${EXTRA_ARGS[@]}"
    fi
    ;;
  Darwin*)
    echo "Running binary (no system profiler auto-invoked on macOS)."
    echo "For CPU profile: run this binary, then in another terminal: sample <pid> 5 -f $PROFILE_DIR/cpu.prof"
    exec "$BINARY" "${EXTRA_ARGS[@]}"
    ;;
  *)
    echo "No system profiler configured for this OS. Running binary directly."
    echo "Binary: $BINARY"
    exec "$BINARY" "${EXTRA_ARGS[@]}"
    ;;
esac
