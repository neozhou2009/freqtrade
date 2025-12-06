# 策略何时开始交易（启动条件、监控与加速指南）

本文档记录了与 SampleStrategy 在启动后何时开始交易相关的关键点、调试方法及加速策略生效的建议。

---

## 1. 简要结论

在默认配置下，策略会在满足以下条件后开始下单：

- 策略拥有足够的历史 candles（由 `startup_candle_count` 决定）。
  - 在 `SampleStrategy` 中：`timeframe = '5m'`，`startup_candle_count = 30`。因此需要大约 30 根 5 分钟蜡烛（约 2.5 小时）的数据。
- 指标计算需要这些历史数据（如 RSI、MACD、EMA 等）。一旦有足够历史数据，策略将在新 candle 收盘时进行计算与信号判定（`process_only_new_candles` 为 True 的情况下）。
- Pairlist 刷新、交易所数据到位、并且账户/配置允许下单。

简言之：如果没有预先下载的历史数据，策略启动后最早也要等大约 30 根 5 分钟蜡烛（约 2.5 小时）。如果你预先下载/导入了历史数据，策略可能立刻开始生成信号并下单（在下个收盘/数据更新时）。

---

## 2. 检查与监控步骤

要确认策略何时准备就绪并下单：

1. **查看日志（最直接）**：
   - 使用 `tail -f` 监听日志：
     ```bash
     tail -f logs/freqtrade.log
     ```
   - 寻找 Buy / Order / Open position 等关键字。

2. **查询交易历史**：
   ```bash
   freqtrade show-trades --config user_data/config.json
   ```

3. **查看 RPC / API UI**：
   - 如果启用了 API，打开 `http://127.0.0.1:8080/` 查看 Open Trades 与 Recent Trades。也可以检查 `/ui_version` 返回。
   ```bash
   curl -sS http://127.0.0.1:8080/ui_version
   ```

4. **确认 Pairlist 与 candle 数据**：
   - 在日志中检查 Pairlist 是否已经刷新：例如 `Whitelist with XX pairs`。
   - 检查数据目录是否存在 5m 的数据 `user_data/data/<exchange>`。

5. **回测或回放**（用于测试）：
   ```bash
   freqtrade backtesting --config user_data/config.json --strategy SampleStrategy --timeframe 5m
   ```

---

## 3. 加速首次下单（测试/开发用途）

如果你要尽快看到交易行为，可以使用以下方法（注意生产环境请谨慎）：

1. **减少 `startup_candle_count`**：
   - 在策略文件中降低 `startup_candle_count`，例如从 30 改为 10：
     ```python
     startup_candle_count = 10
     ```
   - 保存策略并重启 bot，从而减少需要等待的历史 candles 数量。

2. **修改 timeframe（带来更快的 candles）**：
   - 更短 timeframe（例如 '1m'）会更快积累所需数量的 candles：但是指标（如 MACD/EMA）参数可能需要调整。

3. **预先下载/导入历史数据**：
   - 快速填充历史数据让策略立即计算指标并可能下单：
     ```bash
     freqtrade download-data --exchange okx --timeframes 5m --days 2 --config user_data/config.json
     ```
   - 确认文件已存放到 `user_data/data/<exchange>`，然后重启策略。

4. **在 backtesting 上验证**：
   - 使用 backtesting 模式基于历史数据测试策略，快速确认信号生成和预期的 entry/exit 行为。

5. **临时设置 `process_only_new_candles = False`（谨慎）**：
   - 使策略在每次数据变更时都进行计算，但这可能增加噪声与误报，谨慎用于测试。

---

## 4. 常见问题与注意事项

- 如果日志中出现 `FileNotFoundError` 与 API UI 相关的错误（例如 `fallback_file.html`），请确保 UI 目录存在并包含所需的静态文件（可以使用 `freqtrade install-ui` 安装或复制自定义 UI）。
- 如果 `uvicorn` 报 `address already in use`，请检查是否有多个实例尝试绑定同一端口（常见端口 `8080`）。
- CCXT 显示的 `NetworkError` 或 websocket 断连（例如关闭代码 1006）通常表示交易所服务器端断开或网络问题，不直接影响策略的历史数据准备，但如果导致无法获取实时 candles，则会影响信号生成。
- **生产风险**：在真实 SDK/资金的环境不要随意降低 `startup_candle_count` 或更改其它保护参数。 先在 dry-run/backtest 中充分验证。

---

## 5. 示例命令（快速备忘）

```bash
# 运行策略（dry-run 是默认）
freqtrade trade --config user_data/config.json --strategy SampleStrategy

# 下载 2 天 5m 数据（作历史回填）
freqtrade download-data --exchange okx --timeframes 5m --days 2 --config user_data/config.json

# 后台查看日志
tail -f logs/freqtrade.log

# 查询已生成的 trades
freqtrade show-trades --config user_data/config.json

# 简短回测演示
freqtrade backtesting --config user_data/config.json --strategy SampleStrategy --timeframe 5m
```

---

## 6. 后续建议

- 如果你想我为你执行某一步（立即下载历史数据、临时调小 `startup_candle_count`，或者运行一次回测并打印第一次入场时间），请告知哪一项，我会进行相应操作并把结果保存到仓库（例如记录一个回测输出文件）。

---

> 文档生成: 由 Copilot 辅助创建（自动保存到 `docs/strategy-startup-trading.md`）。
