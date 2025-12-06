# Freqtrade 源码开发指南

> 完整的 Freqtrade 开发、调试和贡献指南

## 目录

1. [项目概述](#1-项目概述)
2. [开发环境搭建](#2-开发环境搭建)
3. [项目架构](#3-项目架构)
4. [核心模块详解](#4-核心模块详解)
5. [开发工作流](#5-开发工作流)
6. [测试指南](#6-测试指南)
7. [代码规范](#7-代码规范)
8. [调试技巧](#8-调试技巧)
9. [贡献指南](#9-贡献指南)
10. [常见问题](#10-常见问题)

---

## 1. 项目概述

### 1.1 技术栈

- **语言**: Python 3.11+
- **数据库**: SQLite (SQLAlchemy ORM)
- **交易所接口**: CCXT
- **Web框架**: FastAPI
- **通知**: python-telegram-bot
- **数据分析**: pandas, numpy, TA-Lib
- **机器学习**: scikit-learn, optuna (可选)
- **测试**: pytest

### 1.2 项目特点

- 支持多交易所（现货和期货）
- Dry-run 模拟交易
- 回测和策略优化
- Telegram/WebUI 控制
- 插件化架构（策略、Pairlist、保护机制）

---

## 2. 开发环境搭建

### 2.1 系统要求

- Python >= 3.11
- Git
- TA-Lib (C库)
- 2GB+ RAM
- 1GB+ 磁盘空间

### 2.2 克隆项目

```bash
git clone https://github.com/freqtrade/freqtrade.git
cd freqtrade
git checkout develop  # 开发分支
```

### 2.3 安装 TA-Lib

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get update
sudo apt-get install build-essential wget
wget http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz
tar -xzf ta-lib-0.4.0-src.tar.gz
cd ta-lib/
./configure --prefix=/usr
make
sudo make install
```

#### macOS
```bash
brew install ta-lib
```

#### Windows
```powershell
# 下载预编译的 wheel 文件
# https://github.com/cgohlke/talib-build/releases
pip install TA_Lib‑0.4.XX‑cpXX‑cpXX‑win_amd64.whl
```

### 2.4 创建虚拟环境

```bash
# 使用 venv
python3 -m venv .venv
source .venv/bin/activate  # Linux/macOS
# 或
.venv\Scripts\activate  # Windows

# 或使用 conda
conda create -n freqtrade python=3.11
conda activate freqtrade
```

### 2.5 安装依赖

```bash
# 安装核心依赖
pip install -e .

# 安装开发依赖
pip install -e .[dev]

# 或分别安装
pip install -r requirements.txt
pip install -r requirements-dev.txt
pip install -r requirements-hyperopt.txt  # 可选
pip install -r requirements-plot.txt      # 可选
```

### 2.6 安装 Pre-commit Hooks

```bash
pre-commit install
```

### 2.7 验证安装

```bash
# 运行测试
pytest tests/test_main.py

# 检查版本
freqtrade --version

# 创建配置
freqtrade new-config --config user_data/config.json
```

---

## 3. 项目架构

### 3.1 目录结构

```
freqtrade/
├── freqtrade/              # 核心代码
│   ├── __init__.py
│   ├── main.py            # 入口文件
│   ├── freqtradebot.py    # 主交易逻辑
│   ├── constants.py       # 常量定义
│   ├── worker.py          # 工作线程
│   │
│   ├── commands/          # CLI 命令
│   ├── configuration/     # 配置管理
│   ├── data/             # 数据处理
│   ├── enums/            # 枚举类型
│   ├── exchange/         # 交易所接口
│   ├── optimize/         # 回测和优化
│   ├── persistence/      # 数据库模型
│   ├── plugins/          # 插件系统
│   ├── resolvers/        # 动态加载器
│   ├── rpc/              # RPC 接口
│   ├── strategy/         # 策略基类
│   └── util/             # 工具函数
│
├── tests/                 # 测试代码
├── user_data/            # 用户数据
│   ├── strategies/       # 用户策略
│   ├── data/            # 历史数据
│   └── logs/            # 日志文件
│
├── config_examples/      # 配置示例
├── docs/                # 文档
└── scripts/             # 辅助脚本
```

### 3.2 核心模块关系

```
┌─────────────────────────────────────────────────────┐
│                    main.py                          │
│                  (程序入口)                          │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│                  worker.py                          │
│              (工作线程管理)                          │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│              freqtradebot.py                        │
│              (核心交易逻辑)                          │
└─────┬────────┬────────┬────────┬────────┬──────────┘
      │        │        │        │        │
      ▼        ▼        ▼        ▼        ▼
   Exchange Strategy Wallets  RPC   Persistence
   (交易所) (策略)   (钱包)  (通信)  (数据库)
```

### 3.3 数据流

```
用户配置 → Configuration → FreqtradeBot
                              ↓
                         Exchange API
                              ↓
                         DataProvider
                              ↓
                          Strategy
                              ↓
                      Entry/Exit Signals
                              ↓
                         Order Execution
                              ↓
                         Trade Database
                              ↓
                         RPC Notifications
```

---

## 4. 核心模块详解

### 4.1 FreqtradeBot (freqtradebot.py)

**职责**: 核心交易逻辑控制器

**关键方法**:
```python
class FreqtradeBot:
    def __init__(self, config: Config):
        """初始化交易所、策略、数据库等"""
        
    def process(self):
        """主循环：分析市场、执行交易"""
        
    def enter_positions(self):
        """寻找并执行入场机会"""
        
    def exit_positions(self, trades: List[Trade]):
        """检查并执行出场"""
        
    def create_trade(self, pair: str) -> bool:
        """创建新交易"""
        
    def execute_entry(self, pair, stake_amount, ...):
        """执行入场订单"""
        
    def execute_trade_exit(self, trade, limit, ...):
        """执行出场订单"""
```

**工作流程**:
1. 刷新市场数据
2. 更新未完成订单
3. 检查出场条件
4. 寻找入场机会
5. 执行订单
6. 更新数据库

### 4.2 Exchange (exchange/exchange.py)

**职责**: 交易所接口抽象层

**关键功能**:
```python
class Exchange:
    def create_order(self, pair, ordertype, side, amount, rate, ...):
        """创建订单（dry-run 或实盘）"""
        if self._config["dry_run"]:
            return self.create_dry_run_order(...)
        return self._api.create_order(...)
    
    def create_dry_run_order(self, ...):
        """创建模拟订单"""
        
    def fetch_order(self, order_id, pair):
        """查询订单状态"""
        
    def get_balances(self):
        """获取账户余额"""
```

**Dry-Run 机制**:
- 内存存储: `_dry_run_open_orders`
- 订单ID格式: `dry_run_{side}_{pair}_{timestamp}`
- 价格模拟: 基于订单簿深度
- 成交检查: `check_dry_limit_order_filled()`

### 4.3 Strategy (strategy/interface.py)

**职责**: 策略基类和接口

**必须实现的方法**:
```python
class IStrategy:
    def populate_indicators(self, dataframe, metadata):
        """添加技术指标"""
        return dataframe
    
    def populate_entry_trend(self, dataframe, metadata):
        """生成入场信号"""
        dataframe.loc[条件, 'enter_long'] = 1
        return dataframe
    
    def populate_exit_trend(self, dataframe, metadata):
        """生成出场信号"""
        dataframe.loc[条件, 'exit_long'] = 1
        return dataframe
```

**可选回调**:
```python
def custom_stake_amount(self, pair, current_time, ...):
    """自定义下单金额"""
    
def custom_entry_price(self, pair, trade, ...):
    """自定义入场价格"""
    
def custom_exit_price(self, pair, trade, ...):
    """自定义出场价格"""
    
def confirm_trade_entry(self, pair, order_type, ...):
    """确认是否入场"""
    
def confirm_trade_exit(self, pair, trade, ...):
    """确认是否出场"""
```

### 4.4 Persistence (persistence/trade_model.py)

**数据库模型**:

```python
class Trade(ModelBase):
    """交易记录"""
    id: int
    pair: str
    is_open: bool
    exchange: str
    stake_amount: float
    amount: float
    open_rate: float
    close_rate: float
    stop_loss: float
    orders: List[Order]  # 关联订单
    
class Order(ModelBase):
    """订单记录"""
    id: int
    ft_trade_id: int  # 外键
    order_id: str     # dry_run_xxx 或真实ID
    ft_order_side: str  # 'buy', 'sell', 'stoploss'
    status: str
    amount: float
    filled: float
    price: float
```

**关键操作**:
```python
# 查询
Trade.get_open_trades()
Trade.get_trades_proxy(pair='BTC/USDT', is_open=True)

# 保存
trade.orders.append(order_obj)
Trade.session.add(trade)
Trade.commit()
```

### 4.5 Wallets (wallets.py)

**职责**: 账户余额管理

```python
class Wallets:
    def update(self):
        """更新余额"""
        if not self._config["dry_run"]:
            self._update_live()   # 从交易所获取
        else:
            self._update_dry()    # 从数据库计算
    
    def _update_dry(self):
        """Dry-run 余额计算"""
        tot_profit = Trade.get_total_closed_profit()
        tot_in_trades = sum(trade.stake_amount for trade in open_trades)
        current_stake = self._start_cap + tot_profit - tot_in_trades
    
    def get_trade_stake_amount(self, pair, max_open_trades):
        """计算下单金额"""
```

### 4.6 RPC (rpc/)

**通信接口**:
- **Telegram**: `rpc/telegram.py`
- **REST API**: `rpc/api_server/`
- **Webhook**: `rpc/webhook.py`

```python
class RPCManager:
    def send_msg(self, msg: Dict):
        """发送通知到所有 RPC 通道"""
        
# 消息类型
RPCMessageType.ENTRY        # 入场通知
RPCMessageType.EXIT         # 出场通知
RPCMessageType.STATUS       # 状态更新
RPCMessageType.WARNING      # 警告
```

---

## 5. 开发工作流

### 5.1 创建新功能分支

```bash
git checkout develop
git pull origin develop
git checkout -b feat/your-feature-name
```

### 5.2 开发流程

1. **编写代码**
   ```bash
   # 修改相关文件
   vim freqtrade/your_module.py
   ```

2. **添加类型注解**
   ```python
   def my_function(param: str, count: int = 0) -> bool:
       """
       函数说明
       
       :param param: 参数说明
       :param count: 计数器
       :return: 成功返回 True
       """
       return True
   ```

3. **编写单元测试**
   ```python
   # tests/test_your_module.py
   def test_my_function():
       result = my_function("test", 5)
       assert result is True
   ```

4. **运行测试**
   ```bash
   pytest tests/test_your_module.py -v
   ```

5. **代码检查**
   ```bash
   # 格式化
   ruff format .
   
   # 检查
   ruff check .
   
   # 类型检查
   mypy freqtrade
   ```

6. **提交代码**
   ```bash
   git add .
   git commit -m "feat: add new feature description"
   ```

### 5.3 本地测试完整流程

```bash
# 1. 运行所有测试
pytest

# 2. 运行特定模块测试
pytest tests/test_freqtradebot.py

# 3. 运行单个测试
pytest tests/test_freqtradebot.py::test_create_trade

# 4. 查看覆盖率
pytest --cov=freqtrade --cov-report=html

# 5. 并行测试（加速）
pytest -n auto
```

### 5.4 调试模式运行

```bash
# Dry-run 模式
freqtrade trade --config user_data/config.json --strategy SampleStrategy

# 启用详细日志
freqtrade trade -c config.json -s SampleStrategy -v

# 超详细日志
freqtrade trade -c config.json -s SampleStrategy -vv
```

---

## 6. 测试指南

### 6.1 测试结构

```
tests/
├── conftest.py              # pytest 配置和 fixtures
├── test_freqtradebot.py     # 核心逻辑测试
├── exchange/
│   ├── test_exchange.py     # 交易所测试
│   └── test_binance.py      # 特定交易所测试
├── persistence/
│   └── test_trade_model.py  # 数据库模型测试
└── strategy/
    └── test_interface.py    # 策略接口测试
```

### 6.2 常用 Fixtures

```python
# conftest.py 中定义的常用 fixtures

@pytest.fixture
def default_conf():
    """默认配置"""
    return {
        "dry_run": True,
        "stake_currency": "USDT",
        "exchange": {"name": "binance", ...},
        ...
    }

@pytest.fixture
def mocker():
    """Mock 对象"""
    
@pytest.fixture
def fee():
    """交易手续费"""
    return 0.001
```

### 6.3 编写测试示例

```python
# tests/test_my_feature.py

def test_create_dry_run_order(default_conf, mocker):
    """测试 dry-run 订单创建"""
    # 1. 准备
    exchange = get_patched_exchange(mocker, default_conf)
    
    # 2. 执行
    order = exchange.create_order(
        pair='BTC/USDT',
        ordertype='limit',
        side='buy',
        amount=1.0,
        rate=50000.0,
        leverage=1.0
    )
    
    # 3. 断言
    assert order['id'].startswith('dry_run_')
    assert order['status'] == 'open'
    assert order['amount'] == 1.0
    assert order['price'] == 50000.0

def test_trade_creation(default_conf, mocker, fee):
    """测试交易创建"""
    freqtrade = get_patched_freqtradebot(mocker, default_conf)
    
    # Mock 策略信号
    mocker.patch.multiple(
        'freqtrade.freqtradebot.FreqtradeBot',
        get_entry_signal=MagicMock(return_value=(SignalDirection.LONG, 'test_tag'))
    )
    
    # 执行
    result = freqtrade.create_trade('BTC/USDT')
    
    # 验证
    assert result is True
    trades = Trade.get_open_trades()
    assert len(trades) == 1
    assert trades[0].pair == 'BTC/USDT'
```

### 6.4 Mock 技巧

```python
# Mock 交易所 API
mocker.patch('freqtrade.exchange.Exchange.fetch_ticker', 
             return_value={'last': 50000})

# Mock 时间
mocker.patch('freqtrade.freqtradebot.datetime',
             return_value=datetime(2023, 1, 1))

# Mock 数据库
mocker.patch('freqtrade.persistence.Trade.get_open_trades',
             return_value=[])
```

### 6.5 测试覆盖率

```bash
# 生成覆盖率报告
pytest --cov=freqtrade --cov-report=html

# 查看报告
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
start htmlcov/index.html  # Windows
```

---

## 7. 代码规范

### 7.1 Python 风格

遵循 **PEP 8** 和项目特定规范：

```python
# ✅ 正确
def calculate_profit(
    entry_price: float,
    exit_price: float,
    amount: float,
    fee: float = 0.001
) -> float:
    """
    计算利润
    
    :param entry_price: 入场价格
    :param exit_price: 出场价格
    :param amount: 数量
    :param fee: 手续费率
    :return: 利润金额
    """
    gross_profit = (exit_price - entry_price) * amount
    total_fee = (entry_price + exit_price) * amount * fee
    return gross_profit - total_fee

# ❌ 错误
def calc_profit(e,x,a,f=0.001):
    return (x-e)*a-(e+x)*a*f
```

### 7.2 命名约定

```python
# 类名：大驼峰
class FreqtradeBot:
    pass

# 函数/变量：小写下划线
def create_trade():
    stake_amount = 100.0

# 常量：大写下划线
MAX_OPEN_TRADES = 10
DEFAULT_STAKE_AMOUNT = 100

# 私有方法：前缀下划线
def _internal_method():
    pass
```

### 7.3 类型注解

```python
from typing import Dict, List, Optional, Tuple

def process_trades(
    trades: List[Trade],
    config: Dict[str, Any]
) -> Tuple[int, float]:
    """处理交易列表"""
    count = len(trades)
    total_profit = sum(t.profit for t in trades)
    return count, total_profit

# 可选参数
def get_trade(trade_id: int) -> Optional[Trade]:
    return Trade.query.get(trade_id)
```

### 7.4 文档字符串

```python
def execute_entry(
    self,
    pair: str,
    stake_amount: float,
    price: Optional[float] = None,
    *,
    is_short: bool = False,
    ordertype: Optional[str] = None
) -> bool:
    """
    执行入场订单
    
    :param pair: 交易对
    :param stake_amount: 下单金额
    :param price: 限价（可选）
    :param is_short: 是否做空
    :param ordertype: 订单类型
    :return: 成功返回 True
    :raises: DependencyException 如果余额不足
    """
    pass
```

### 7.5 代码检查工具

#### Ruff (格式化和检查)
```bash
# 格式化代码
ruff format .

# 检查问题
ruff check .

# 自动修复
ruff check --fix .
```

#### Mypy (类型检查)
```bash
# 检查整个项目
mypy freqtrade

# 检查特定文件
mypy freqtrade/freqtradebot.py
```

#### Pre-commit (提交前检查)
```bash
# 手动运行所有检查
pre-commit run --all-files

# 只检查暂存文件
pre-commit run
```

---

## 8. 调试技巧

### 8.1 使用 Python Debugger

```python
# 在代码中插入断点
import pdb; pdb.set_trace()

# 或使用 breakpoint() (Python 3.7+)
breakpoint()

# 常用命令
# n - next (下一行)
# s - step (进入函数)
# c - continue (继续执行)
# p variable - print (打印变量)
# l - list (显示代码)
# q - quit (退出)
```

### 8.2 使用 VS Code 调试

创建 `.vscode/launch.json`:

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Freqtrade Trade",
            "type": "python",
            "request": "launch",
            "module": "freqtrade",
            "args": [
                "trade",
                "--config", "user_data/config.json",
                "--strategy", "SampleStrategy",
                "-v"
            ],
            "console": "integratedTerminal",
            "justMyCode": false
        },
        {
            "name": "Pytest Current File",
            "type": "python",
            "request": "launch",
            "module": "pytest",
            "args": [
                "${file}",
                "-v"
            ],
            "console": "integratedTerminal"
        }
    ]
}
```

### 8.3 日志调试

```python
import logging

logger = logging.getLogger(__name__)

# 不同级别的日志
logger.debug("详细调试信息")
logger.info("一般信息")
logger.warning("警告信息")
logger.error("错误信息")
logger.exception("异常信息（包含堆栈）")

# 在配置中设置日志级别
# config.json
{
    "verbosity": 3  # 0=ERROR, 1=WARNING, 2=INFO, 3=DEBUG
}
```

### 8.4 数据库调试

```python
# 查看 SQL 语句
import logging
logging.getLogger('sqlalchemy.engine').setLevel(logging.INFO)

# 直接查询数据库
from freqtrade.persistence import Trade, Order

# 查看所有交易
trades = Trade.get_trades([]).all()
for trade in trades:
    print(f"{trade.pair}: {trade.profit_ratio:.2%}")

# 查看订单
orders = Order.get_open_orders()
for order in orders:
    print(f"{order.order_id}: {order.status}")
```

### 8.5 性能分析

```python
import cProfile
import pstats

# 分析函数性能
profiler = cProfile.Profile()
profiler.enable()

# 执行代码
freqtrade.process()

profiler.disable()
stats = pstats.Stats(profiler)
stats.sort_stats('cumulative')
stats.print_stats(20)  # 显示前 20 个最慢的函数
```

### 8.6 内存调试

```python
import tracemalloc

# 开始追踪
tracemalloc.start()

# 执行代码
freqtrade.process()

# 获取内存快照
snapshot = tracemalloc.take_snapshot()
top_stats = snapshot.statistics('lineno')

for stat in top_stats[:10]:
    print(stat)
```

---

## 9. 贡献指南

### 9.1 贡献流程

1. **Fork 项目**
   ```bash
   # 在 GitHub 上 Fork freqtrade/freqtrade
   git clone https://github.com/YOUR_USERNAME/freqtrade.git
   cd freqtrade
   git remote add upstream https://github.com/freqtrade/freqtrade.git
   ```

2. **创建功能分支**
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout -b feat/your-feature
   ```

3. **开发和测试**
   ```bash
   # 编写代码
   # 添加测试
   pytest tests/
   
   # 代码检查
   ruff format .
   ruff check .
   mypy freqtrade
   ```

4. **提交代码**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   git push origin feat/your-feature
   ```

5. **创建 Pull Request**
   - 在 GitHub 上创建 PR
   - 目标分支: `develop`
   - 填写 PR 模板
   - 等待 CI 检查通过
   - 响应 Review 意见

### 9.2 Commit 消息规范

使用 [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# 格式
<type>(<scope>): <subject>

# 类型
feat:     新功能
fix:      Bug 修复
docs:     文档更新
style:    代码格式（不影响功能）
refactor: 重构
test:     测试相关
chore:    构建/工具相关

# 示例
feat(exchange): add support for OKX exchange
fix(strategy): correct RSI calculation in populate_indicators
docs(readme): update installation instructions
test(persistence): add tests for Trade model
```

### 9.3 PR 检查清单

- [ ] 代码通过所有测试 (`pytest`)
- [ ] 代码符合规范 (`ruff check`)
- [ ] 类型检查通过 (`mypy`)
- [ ] 添加了必要的单元测试
- [ ] 更新了相关文档
- [ ] Commit 消息符合规范
- [ ] PR 描述清晰完整
- [ ] 针对 `develop` 分支

### 9.4 代码审查要点

**作为贡献者**:
- 保持 PR 小而专注
- 及时响应 Review 意见
- 解释设计决策
- 保持友好和专业

**作为审查者**:
- 检查代码逻辑正确性
- 验证测试覆盖率
- 确认符合项目规范
- 提供建设性反馈

---

## 10. 常见问题

### 10.1 开发环境问题

**Q: TA-Lib 安装失败**
```bash
# 确保安装了 C 库
# Linux
sudo apt-get install build-essential
# macOS
brew install ta-lib

# 然后安装 Python 包
pip install TA-Lib
```

**Q: 依赖冲突**
```bash
# 清理环境重新安装
pip uninstall -y freqtrade
pip cache purge
pip install -e .[dev]
```

**Q: Pre-commit 检查失败**
```bash
# 更新 pre-commit hooks
pre-commit autoupdate
pre-commit install

# 手动修复
ruff format .
ruff check --fix .
```

### 10.2 测试问题

**Q: 测试超时**
```bash
# 增加超时时间
pytest --timeout=300

# 或禁用超时
pytest --timeout=0
```

**Q: 数据库锁定**
```bash
# 删除测试数据库
rm -f tradesv3.dryrun.sqlite
rm -f tradesv3.sqlite

# 重新运行测试
pytest
```

**Q: Mock 不生效**
```python
# 确保 Mock 路径正确
# ❌ 错误
mocker.patch('exchange.Exchange.fetch_ticker')

# ✅ 正确
mocker.patch('freqtrade.exchange.Exchange.fetch_ticker')
```

### 10.3 运行时问题

**Q: Dry-run 订单不成交**
```python
# 检查价格是否穿越订单簿
# 限价单需要价格达到才会成交
# 或使用市价单立即成交
{
    "order_types": {
        "entry": "market",  # 改为市价单
        "exit": "market"
    }
}
```

**Q: 策略不执行**
```bash
# 检查日志
freqtrade trade -c config.json -s YourStrategy -vv

# 常见原因：
# 1. 没有交易对在白名单
# 2. 余额不足
# 3. 策略信号条件未满足
# 4. Pairlock 锁定
```

**Q: 内存占用过高**
```python
# 减少数据帧大小
{
    "startup_candle_count": 100,  # 减少启动蜡烛数
    "reduce_df_footprint": true   # 启用数据帧压缩
}
```

### 10.4 调试技巧

**Q: 如何调试策略信号？**
```python
# 在策略中添加日志
import logging
logger = logging.getLogger(__name__)

def populate_entry_trend(self, dataframe, metadata):
    conditions = []
    
    # 添加调试日志
    logger.info(f"Processing {metadata['pair']}")
    logger.debug(f"RSI: {dataframe['rsi'].iloc[-1]}")
    
    conditions.append(dataframe['rsi'] < 30)
    
    if conditions:
        dataframe.loc[reduce(lambda x, y: x & y, conditions), 'enter_long'] = 1
    
    return dataframe
```

**Q: 如何查看订单详情？**
```python
# 使用 Telegram 命令
/status
/status 123  # 查看特定交易

# 或查看数据库
from freqtrade.persistence import Trade, Order

trade = Trade.get_trades([Trade.id == 123]).first()
for order in trade.orders:
    print(f"{order.order_id}: {order.status} - {order.filled}/{order.amount}")
```

**Q: 如何重现 Bug？**
```python
# 1. 记录完整配置
freqtrade show-config -c config.json > debug_config.json

# 2. 导出数据库
sqlite3 tradesv3.sqlite .dump > trades_dump.sql

# 3. 记录日志
freqtrade trade -c config.json -vv 2>&1 | tee debug.log

# 4. 在 Issue 中提供：
# - 配置文件（移除敏感信息）
# - 相关日志
# - 复现步骤
# - 预期行为 vs 实际行为
```

---

## 11. 高级开发主题

### 11.1 添加新交易所支持

```python
# freqtrade/exchange/your_exchange.py

from freqtrade.exchange import Exchange

class YourExchange(Exchange):
    """
    YourExchange 交易所实现
    """
    
    _ft_has: Dict = {
        "ohlcv_candle_limit": 1000,
        "trades_pagination": "id",
        # ... 其他特性
    }
    
    def _ccxt_config(self) -> Dict:
        """CCXT 配置"""
        return {
            "enableRateLimit": True,
            "rateLimit": 50,
        }
    
    def additional_exchange_init(self) -> None:
        """额外初始化"""
        pass
```

### 11.2 创建自定义 Pairlist

```python
# user_data/pairlists/CustomPairlist.py

from freqtrade.plugins.pairlist.IPairList import IPairList

class CustomPairlist(IPairList):
    
    def needstickers(self) -> bool:
        """是否需要 ticker 数据"""
        return True
    
    def short_desc(self) -> str:
        """简短描述"""
        return "Custom pairlist filter"
    
    def filter_pairlist(self, pairlist, tickers):
        """过滤交易对列表"""
        # 自定义过滤逻辑
        filtered = [p for p in pairlist if self._validate_pair(p, tickers)]
        return filtered
    
    def _validate_pair(self, pair, tickers):
        """验证单个交易对"""
        ticker = tickers.get(pair)
        if not ticker:
            return False
        
        # 自定义条件
        return ticker['quoteVolume'] > 1000000
```

### 11.3 实现自定义保护机制

```python
# user_data/protections/CustomProtection.py

from freqtrade.plugins.protections import IProtection

class CustomProtection(IProtection):
    
    def short_desc(self) -> str:
        return "Custom protection"
    
    def global_stop(self, date_now: datetime) -> Optional[PairLockReason]:
        """全局停止检查"""
        # 检查是否需要全局停止交易
        if self._should_stop_globally():
            return PairLockReason(
                reason="Custom global stop triggered",
                lock_end_time=date_now + timedelta(hours=1)
            )
        return None
    
    def stop_per_pair(self, pair, date_now) -> Optional[PairLockReason]:
        """单个交易对停止检查"""
        # 检查特定交易对
        if self._should_stop_pair(pair):
            return PairLockReason(
                reason=f"Custom stop for {pair}",
                lock_end_time=date_now + timedelta(minutes=30)
            )
        return None
```

### 11.4 扩展 REST API

```python
# freqtrade/rpc/api_server/api_custom.py

from fastapi import APIRouter, Depends
from freqtrade.rpc.api_server.deps import get_rpc

router = APIRouter()

@router.get('/custom/stats', tags=['custom'])
def get_custom_stats(rpc=Depends(get_rpc)):
    """自定义统计接口"""
    return {
        "total_trades": len(rpc._freqtrade.get_trades()),
        "custom_metric": calculate_custom_metric()
    }

# 在 api_server.py 中注册
from freqtrade.rpc.api_server import api_custom
app.include_router(api_custom.router, prefix="/api/v1")
```

---

## 12. 性能优化

### 12.1 策略优化

```python
# ❌ 低效：每次都重新计算
def populate_indicators(self, dataframe, metadata):
    for i in range(len(dataframe)):
        dataframe.loc[i, 'custom'] = expensive_calculation(dataframe.loc[i])
    return dataframe

# ✅ 高效：向量化操作
def populate_indicators(self, dataframe, metadata):
    dataframe['custom'] = ta.SMA(dataframe['close'], timeperiod=20)
    return dataframe
```

### 12.2 数据库优化

```python
# ❌ N+1 查询问题
trades = Trade.get_open_trades()
for trade in trades:
    orders = trade.orders  # 每次都查询数据库

# ✅ 预加载关联数据
from sqlalchemy.orm import joinedload

trades = Trade.session.query(Trade)\
    .options(joinedload(Trade.orders))\
    .filter(Trade.is_open.is_(True))\
    .all()
```

### 12.3 缓存策略

```python
from cachetools import TTLCache, cached

# 缓存 ticker 数据
ticker_cache = TTLCache(maxsize=100, ttl=60)

@cached(ticker_cache)
def get_ticker(pair: str):
    return exchange.fetch_ticker(pair)
```

### 12.4 并行处理

```python
from concurrent.futures import ThreadPoolExecutor

def analyze_pairs_parallel(pairs):
    with ThreadPoolExecutor(max_workers=4) as executor:
        results = executor.map(analyze_pair, pairs)
    return list(results)
```

---

## 13. 安全最佳实践

### 13.1 API 密钥管理

```python
# ❌ 不要硬编码
config = {
    "exchange": {
        "key": "your_api_key",
        "secret": "your_secret"
    }
}

# ✅ 使用环境变量
import os

config = {
    "exchange": {
        "key": os.getenv("EXCHANGE_API_KEY"),
        "secret": os.getenv("EXCHANGE_API_SECRET")
    }
}
```

### 13.2 配置文件安全

```bash
# .gitignore 中排除敏感文件
user_data/config*.json
user_data/*.sqlite
.env
*.key
```

### 13.3 日志脱敏

```python
import logging

# 自动脱敏敏感信息
def sanitize_config(config):
    safe_config = config.copy()
    if 'exchange' in safe_config:
        safe_config['exchange']['key'] = '***'
        safe_config['exchange']['secret'] = '***'
    return safe_config

logger.info(f"Config: {sanitize_config(config)}")
```

---

## 14. 文档编写

### 14.1 代码文档

```python
class MyClass:
    """
    类的简短描述
    
    详细说明类的用途和行为
    
    Attributes:
        attr1: 属性1说明
        attr2: 属性2说明
    
    Example:
        >>> obj = MyClass()
        >>> obj.method()
        'result'
    """
    
    def method(self, param: str) -> str:
        """
        方法说明
        
        :param param: 参数说明
        :return: 返回值说明
        :raises ValueError: 异常说明
        """
        pass
```

### 14.2 Markdown 文档

```markdown
# 功能标题

## 概述

简短描述功能

## 使用方法

\```python
# 代码示例
from freqtrade import FreqtradeBot
\```

## 配置

\```json
{
    "option": "value"
}
\```

## 注意事项

- 重要提示1
- 重要提示2
```

---

## 15. 持续集成

### 15.1 GitHub Actions

项目使用 GitHub Actions 进行 CI/CD：

```yaml
# .github/workflows/ci.yml
name: Freqtrade CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'
      - name: Install dependencies
        run: |
          pip install -e .[dev]
      - name: Run tests
        run: pytest
      - name: Run linters
        run: |
          ruff check .
          mypy freqtrade
```

### 15.2 本地 CI 模拟

```bash
# 运行完整的 CI 检查
./scripts/run_ci_checks.sh

# 或手动执行
pytest
ruff check .
mypy freqtrade
```

---

## 16. 资源链接

### 16.1 官方资源

- **文档**: https://www.freqtrade.io
- **GitHub**: https://github.com/freqtrade/freqtrade
- **Discord**: https://discord.gg/p7nuUNVfP7
- **论坛**: https://github.com/freqtrade/freqtrade/discussions

### 16.2 相关项目

- **FreqUI**: Web 界面
- **freqtrade-strategies**: 策略集合
- **CCXT**: 交易所统一接口

### 16.3 学习资源

- Python 官方文档
- SQLAlchemy 文档
- FastAPI 文档
- pytest 文档

---

## 17. 总结

### 17.1 开发检查清单

**开始开发前**:
- [ ] Fork 并克隆项目
- [ ] 安装开发依赖
- [ ] 配置 pre-commit hooks
- [ ] 阅读相关文档

**开发过程中**:
- [ ] 遵循代码规范
- [ ] 添加类型注解
- [ ] 编写单元测试
- [ ] 更新文档
- [ ] 运行本地测试

**提交 PR 前**:
- [ ] 所有测试通过
- [ ] 代码检查通过
- [ ] Commit 消息规范
- [ ] PR 描述完整
- [ ] 针对 develop 分支

### 17.2 获取帮助

遇到问题时：

1. **查看文档**: https://www.freqtrade.io
2. **搜索 Issues**: 可能已有解决方案
3. **Discord 社区**: 实时讨论
4. **创建 Issue**: 详细描述问题

### 17.3 贡献方式

不仅限于代码：

- 报告 Bug
- 改进文档
- 分享策略
- 回答问题
- 翻译文档

---

**祝你开发愉快！Happy Trading! 🚀**
