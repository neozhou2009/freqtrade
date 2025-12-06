#!/usr/bin/env bash
# Download top N pairs' historical data using freqtrade pairlist plugin
# By default: exchange=okx timeframe=5m days=14 pairlist=VolumePairList number_assets=20
# Usage: ./download_top_pairs.sh [--exchange okx] [--timeframe 5m] [--days 14] [--number 20] [--config user_data/config.json] [--dry-run] [--erase-if-incomplete]

set -euo pipefail

# Defaults
EXCHANGE="okx"
TIMEFRAME="5m"
DAYS=14
NUMBER=20
CONFIG_PATH="user_data/config.json"
QUOTE="USDT"
DRY_RUN=false
ERASE_IF_INCOMPLETE=false
STRICT_IDEMPOTENT=true
MIN_TOLERANCE=5 # rows less than min_rows - tolerance triggers re-download

# Lock dir to avoid concurrent runs
LOCKDIR="/tmp/download_top_pairs.lock"

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  --exchange EXCHANGE    Exchange name (default: ${EXCHANGE})
  --timeframe TF         Timeframe (default: ${TIMEFRAME})
  --days DAYS            Number of days of history (default: ${DAYS})
  --number N             Number of assets to pick from pairlist (default: ${NUMBER})
  --config PATH          Path to config.json (default: ${CONFIG_PATH})
  --quote QUOTE          Quote (default: ${QUOTE})
  --dry-run              Only show commands and pairs (don't download)
  --erase-if-incomplete  Erase+redownload if rows < expected
  --no-strict            Don't enforce strict idempotency (timestamp coverage check)
  -h, --help             Show this help msg

Example:
  $0 --exchange okx --timeframe 5m --days 14 --number 20 --config user_data/config.json

EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --exchange)
      EXCHANGE="$2"; shift 2;;
    --timeframe)
      TIMEFRAME="$2"; shift 2;;
    --days)
      DAYS="$2"; shift 2;;
    --number)
      NUMBER="$2"; shift 2;;
    --config)
      CONFIG_PATH="$2"; shift 2;;
    --quote)
      QUOTE="$2"; shift 2;;
    --dry-run)
      DRY_RUN=true; shift 1;;
    --erase-if-incomplete)
      ERASE_IF_INCOMPLETE=true; shift 1;;
    --no-strict)
      STRICT_IDEMPOTENT=false; shift 1;;
    -h|--help)
      usage; exit 0;;
    *)
      echo "Unknown arg: $1"; usage; exit 1;;
  esac
done

# Check for freqtrade
if ! command -v freqtrade >/dev/null 2>&1; then
  echo "Error: 'freqtrade' not found in PATH. Activate your venv or add the CLI to PATH." >&2
  exit 1
fi

# Compute expected rows for given timeframe & days
# 5m timeframe rows per day = 24 * 60 / 5 = 288. Compute generically:
TF_MINUTES=$(echo "$TIMEFRAME" | sed 's/m$//; s/h$/*60/g' | sed 's/h$/*60/; s/m$/*1/')
# Simpler: assume numeric m value parse
if [[ "$TIMEFRAME" =~ ^([0-9]+)m$ ]]; then
  MINUTES=${BASH_REMATCH[1]}
elif [[ "$TIMEFRAME" =~ ^([0-9]+)h$ ]]; then
  MINUTES=$(( ${BASH_REMATCH[1]} * 60 ))
else
  MINUTES=5
fi
ROWS_PER_DAY=$(( (24*60) / MINUTES ))
MIN_ROWS=$(( ROWS_PER_DAY * DAYS ))

echo "Starting top pair downloads for exchange: ${EXCHANGE}, timeframe: ${TIMEFRAME}, days: ${DAYS}, number: ${NUMBER}, config: ${CONFIG_PATH}"

# Fetch pairlist using freqtrade test-pairlist (JSON), parse pairs using python
PAIRLIST_OUTPUT=$(freqtrade test-pairlist --config "$CONFIG_PATH" --exchange "$EXCHANGE" --print-json --quote "$QUOTE" 2>&1 || true)
PAIRLIST_JSON=$(echo "$PAIRLIST_OUTPUT" | tr -d '\n' | sed -n 's/.*\(\[[^]]*\]\).*/\1/p' || true)
if [ -z "$PAIRLIST_JSON" ]; then
  echo "Failed to obtain pairlist JSON. Aborting. See above logs for details." >&2
  echo "Raw output from freqtrade test-pairlist:" >&2
  echo "$PAIRLIST_OUTPUT" >&2
  exit 1
fi

# Use python to safely parse JSON and output the top $NUMBER pairs line by line (handles quoting & spacing)
PAIRS=$(python3 - <<PY
import sys, json
arr = json.loads('''$PAIRLIST_JSON''')
for i,p in enumerate(arr):
    if i >= $NUMBER:
        break
    print(p)
PY
)

if [ -z "$PAIRS" ]; then
  echo "No pairs found in pairlist." >&2
  exit 1
fi

echo "Pairs to download (top $NUMBER):"
printf '%s\n' "$PAIRS"

# Download function
download_pair() {
  local pair="$1"
  local cmd=(freqtrade download-data --exchange "$EXCHANGE" --timeframes "$TIMEFRAME" --days "$DAYS" --pairs "$pair" --config "$CONFIG_PATH")
  echo "=> Downloading: $pair"
  if [ "$DRY_RUN" = true ]; then
    echo "DRY RUN: ${cmd[*]}"
  else
    "${cmd[@]}" || { echo "Download failed for $pair" >&2; return 1; }
  fi
}

# For file checking we will use a small python one-liner
read_rows() {
  local pair="$1"
  fpair=$(echo "$pair" | sed 's/\//_/g')
  fpath="user_data/data/${EXCHANGE}/${fpair}-${TIMEFRAME}.feather"
  if [ ! -f "$fpath" ]; then
    echo 0
    return
  fi
  python - <<PY
import sys
import pandas as pd
try:
    df = pd.read_feather('$fpath')
    print(len(df))
except Exception as e:
    print(0)
PY
}

get_coverage() {
  # prints min_ts,max_ts as ISO strings in UTC (or empty strings if file doesn't exist or error)
  local pair="$1"
  fpair=$(echo "$pair" | sed 's/\//_/g')
  fpath="user_data/data/${EXCHANGE}/${fpair}-${TIMEFRAME}.feather"
  if [ ! -f "$fpath" ]; then
    echo ","
    return
  fi
  python3 - <<PY
import sys
import pandas as pd
from datetime import datetime, timezone
f='$fpath'
try:
  df=pd.read_feather(f)
  if 'date' not in df.columns:
    print(',')
  else:
    mn = df['date'].min().tz_convert('UTC')
    mx = df['date'].max().tz_convert('UTC')
    print(mn.isoformat(), mx.isoformat())
except Exception as e:
  print(',', file=sys.stdout)
PY
}

# create a simple lockdir (prevent concurrent runs)
create_lock() {
  if mkdir "$LOCKDIR" 2>/dev/null; then
    trap 'rm -rf "$LOCKDIR"' EXIT
    return 0
  else
    echo "Another instance of this script is running (lock dir $LOCKDIR exists). Exiting." >&2
    return 1
  fi
}

remove_lock() {
  rm -rf "$LOCKDIR" || true
}

echo
for pair in $PAIRS; do
  create_lock || exit 1
  # get coverage
  cov=$(get_coverage "$pair")
  start_ts=""
  end_ts=""
  if [ -n "$cov" ]; then
    # parse output
    start_ts=$(echo "$cov" | awk '{print $1}')
    end_ts=$(echo "$cov" | awk '{print $2}')
  fi
  # compute required timestamps in epoch seconds and floor to timeframe
  now_epoch=$(date -u +%s)
  TF_SECONDS=$((MINUTES * 60))
  # last closed candle start (epoch)
  required_end_epoch=$(( ((now_epoch - TF_SECONDS) / TF_SECONDS) * TF_SECONDS ))
  # required_start_epoch floored to TF and minus DAYS
  required_start_epoch=$(( required_end_epoch - (DAYS * 24 * 3600) + TF_SECONDS ))

  # convert to simple epoch seconds for given ISO datetime string using GNU date
  to_epoch() {
    if [ -z "$1" ]; then
      echo 0
      return
    fi
    epoch=$(date -u -d "$1" +%s 2>/dev/null || echo 0)
    echo $epoch
  }
  start_epoch=0
  end_epoch=0
  # required_start_epoch and required_end_epoch already computed
  if [ -n "$start_ts" ]; then
    start_epoch=$(to_epoch "$start_ts")
  fi
  if [ -n "$end_ts" ]; then
    end_epoch=$(to_epoch "$end_ts")
  fi

  # tolerance: allow one timeframe step difference
  TF_MINUTES=${TF_MINUTES:-$MINUTES}
  TOL_SECONDS=$((TF_MINUTES*60))

  # compute human readable required start/end for messages
  required_start_iso=$(date -u -d "@$required_start_epoch" -Iseconds)
  required_end_iso=$(date -u -d "@$required_end_epoch" -Iseconds)
  if [ "$STRICT_IDEMPOTENT" = true ] && [ "$start_epoch" -ne 0 ] && [ "$end_epoch" -ne 0 ] && [ "$start_epoch" -le "$required_start_epoch" ] && [ "$end_epoch" -ge $((required_end_epoch - TOL_SECONDS)) ]; then
    echo "Skipping $pair: coverage start=$start_ts end=$end_ts covers required range ($required_start_iso to $required_end_iso)."
    remove_lock
    continue
  fi

  if [ "$start_epoch" -eq 0 ]; then
    # no file: just download
    download_pair "$pair"
  elif [ "$start_epoch" -gt "$required_start_epoch" ]; then
    # need to prepend
    echo "Prepending for $pair: start $start_ts is newer than required $required_start_iso."
    if [ "$DRY_RUN" = true ]; then
      echo "DRY RUN: freqtrade download-data --prepend --exchange $EXCHANGE --timeframes $TIMEFRAME --days $DAYS --pairs '$pair' --config $CONFIG_PATH"
    else
      freqtrade download-data --prepend --exchange "$EXCHANGE" --timeframes "$TIMEFRAME" --days "$DAYS" --pairs "$pair" --config "$CONFIG_PATH" || echo "Prepend failed for $pair" >&2
    fi
  elif [ "$end_epoch" -lt $((required_end_epoch - TOL_SECONDS)) ]; then
    # need to get the latest (normal download should append)
    echo "Appending / re-downloading missing latest for $pair: end $end_ts is older than required $required_end_iso."
    download_pair "$pair"
  else
    # fallback: normal download
    download_pair "$pair"
  fi
  remove_lock
done
remove_lock

# Optionally re-erase if incomplete
if [ "$ERASE_IF_INCOMPLETE" = true ]; then
  echo
  echo "Verifying row counts with threshold ${MIN_ROWS} rows..."
  for pair in $PAIRS; do
    rows=$(read_rows "$pair")
    echo "Pair ${pair}: rows=${rows}"
    if [ "$rows" -lt $((MIN_ROWS - MIN_TOLERANCE)) ]; then
      echo " - rows (${rows}) < expected (${MIN_ROWS}). Erase & redownload..."
      if [ "$DRY_RUN" = true ]; then
        echo "DRY RUN: freqtrade download-data --erase --exchange $EXCHANGE --timeframes $TIMEFRAME --days $DAYS --pairs '$pair' --config $CONFIG_PATH"
      else
        freqtrade download-data --erase --exchange "$EXCHANGE" --timeframes "$TIMEFRAME" --days "$DAYS" --pairs "$pair" --config "$CONFIG_PATH" || echo "Erase+download failed for $pair" >&2
      fi
    fi
  done
fi

# Summary
echo
echo "Summary of files and row counts:"
python3 - <<PY
import glob, pandas as pd
files = glob.glob('user_data/data/${EXCHANGE}/*-${TIMEFRAME}.feather')
files.sort()
for f in files:
    name = f.replace('user_data/data/${EXCHANGE}/', '').replace('-${TIMEFRAME}.feather', '').replace('_','/')
    try:
        df = pd.read_feather(f)
        print(f"{name} -> {len(df)} rows")
    except Exception as e:
        print(f"{name} -> ERROR ({e})")
PY

# Done

echo "Done."
