#!/usr/bin/env python3
"""Summarize backtest zip files under user_data/backtest_results.

Usage: python3 scripts/summarize_backtests.py [DIR]
"""

import json
import sys
import zipfile
from pathlib import Path


def summarize_zip(zip_path: Path):
    # find the json file (ends with .json and not *config.json)
    with zipfile.ZipFile(zip_path, "r") as z:
        names = [n for n in z.namelist() if n.endswith(".json") and not n.endswith("_config.json")]
        if not names:
            return None
        name = names[0]
        data = json.loads(z.read(name))
        # Find the strategy key and read top-level metrics
        strategy = next(iter(data["strategy"].values()))
        pairlist = strategy.get("pairlist", [])
        results = {
            "zip": zip_path.name,
            "pair": pairlist[0] if pairlist else "N/A",
            "trades": strategy.get("total_trades", 0),
            "winrate": round(strategy.get("winrate", 0) * 100, 2),
            "profit_total_pct": round(strategy.get("profit_total_pct", 0) * 100, 4),
            "final_balance": strategy.get("final_balance", 0),
            "cagr": round(strategy.get("cagr", 0) * 100, 4),
            "max_drawdown_abs": strategy.get("max_drawdown_abs", 0),
        }
        return results


def main():
    d = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("user_data/backtest_results")
    zips = sorted(d.glob("backtest-result-*.zip"))
    rows = []
    for z in zips:
        s = summarize_zip(z)
        if s:
            rows.append(s)

    if not rows:
        print("No backtest results found in", d)
        return
    print("zip,pair,trades,winrate(%),profit_total_pct(%),final_balance,cagr(%),max_drawdown_abs")
    for r in rows:
        print(
            "{zip},{pair},{trades},{winrate},{profit_total_pct},{final_balance},{cagr},{max_drawdown_abs}".format(
                **r
            )
        )


if __name__ == "__main__":
    main()
