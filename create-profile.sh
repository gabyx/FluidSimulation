#!/bin/bash
set -u
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

function cleanup() {
    echo "Killall rsfluid."
    killall rsfluid || true

    [ -d "$tempDir" ] && rm -rf "$tempDir"
}

trap cleanup EXIT

scripts="$DIR/profile"

cd "$DIR"
cargo build --profile release-bench --bin rsfluid

nohup target/release-bench/rsfluid -e 10.0 -t 0.016 --incompress-iters=100 &>/dev/null &
sleep 2
pid=$(pgrep rsfluid)

tempDir=$(mktemp -d) && cd "$tempDir"
sample "$pid" -f output.prof

filtercalltree output.prof |
    "$scripts/stackcollapse-sample.awk" |
    "$scripts/rust-unmangle" |
    "$scripts/flamegraph.pl" --width 1200 >"$DIR/flamegraph.svg"
