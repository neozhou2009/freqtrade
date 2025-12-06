#!/usr/bin/env bash
set -euo pipefail

# Run per-pair backtesting using the correct --timerange syntax
# Usage: backtest_top_pairs.sh [--number N] [--days D] [--timeframe TF] [--config CONFIG] [--strategy NAME] [--dry-run]

NUM=5
DAYS=14
TIMEFRAME="5m"
CONFIG="user_data/config.json"
STRATEGY="SampleStrategy"
DRY_RUN=""
BACKTEST_DIR="user_data/backtest_results"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --number)
      NUM="$2"; shift 2;;
    --days)
      DAYS="$2"; shift 2;;
    --timeframe)
      TIMEFRAME="$2"; shift 2;;
    --config)
      CONFIG="$2"; shift 2;;
    --strategy)
      STRATEGY="$2"; shift 2;;
    --dry-run)
      DRY_RUN="--dry-run"; shift 1;;
    --help|-h)
      echo "Usage: $0 [--number N] [--days D] [--timeframe TF] [--config CONFIG] [--strategy NAME] [--dry-run]"; exit 0;;
    *)
      echo "Unknown option: $1"; exit 1;;
  esac
done

mkdir -p "$BACKTEST_DIR"

# Calculate timerange in YYYYMMDD-YYYYMMDD format (UTC)
END_DATE=$(date -u +%Y%m%d)
START_DATE=$(date -u -d "${DAYS} days ago" +%Y%m%d)
TIMERANGE="${START_DATE}-${END_DATE}"

echo "Timerange: ${TIMERANGE} (timeframe ${TIMEFRAME})"
echo "Fetching top $NUM pairs from pairlist..."

PAIRS_JSON=$(freqtrade test-pairlist --config "$CONFIG" --exchange okx --print-json --quote USDT 2>/dev/null || true)
if [[ -z "$PAIRS_JSON" ]]; then
  echo "Failed to fetch pairlist with freqtrade test-pairlist" >&2
  exit 1
fi

# Extract top N pairs via python
IFS=$'\n' read -r -d '' -a PAIRS < <(printf '%s' "$PAIRS_JSON" | NUM=$NUM python -c "import json,sys,os; data=json.load(sys.stdin); top=data[:int(os.environ.get('NUM', '5'))]; print('\n'.join(top))" && printf '\0')

if [[ ${#PAIRS[@]} -eq 0 ]]; then
  echo "No pairs found from pairlist" >&2
  exit 1
fi

echo "Will run backtests for the following pairs (up to $NUM):"
for p in "${PAIRS[@]}"; do
  echo " - $p"
done

TEMP_CONFIG="$CONFIG"
for pair in "${PAIRS[@]}"; do
  # Create a temporary config per pair to use StaticPairList for backtesting
  TEMP_CONFIG="/tmp/freqtrade_backtest_config_$(date +%s)_${pair//\//_}.json"
  python - <<PY > "$TEMP_CONFIG"
import json
cfg=json.load(open("$CONFIG"))
cfg['pairlists'] = [{"method": "StaticPairList", "pairs": ["$pair"]}]
print(json.dumps(cfg))
PY
  echo "--- Backtesting $pair ---"
  out_file="${BACKTEST_DIR}/backtest_${pair//\//_}_${TIMEFRAME}_${START_DATE}_${END_DATE}.json"
  cmd=(freqtrade backtesting -c "$TEMP_CONFIG" -s "$STRATEGY" -i "$TIMEFRAME" -p "$pair" --timerange "$TIMERANGE" --export trades --backtest-directory "$BACKTEST_DIR")
  if [[ -n "$DRY_RUN" ]]; then
    echo DRY: ${cmd[@]}
  else
    echo Running: ${cmd[@]}
    "${cmd[@]}"
    echo "Output saved under: $BACKTEST_DIR (look for backtest_*.json)"
  fi
done

echo "Backtesting completed for up to $NUM pairs. Results are in $BACKTEST_DIR"
