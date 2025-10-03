"""
Freqtrade配置生成器
"""
import json
import os
import logging
from typing import Dict, Any, Optional
from jinja2 import Template

logger = logging.getLogger(__name__)

class ConfigGenerator:
    """Freqtrade配置生成器"""
    
    def __init__(self, template_path: str = None):
        self.template_path = template_path or "/freqtrade/config_templates"
        
    def generate_config(self, bot_config: Dict[str, Any]) -> str:
        """生成Freqtrade配置文件"""
        try:
            # 读取模板
            template_file = os.path.join(self.template_path, "base_config.json")
            with open(template_file, 'r') as f:
                template_content = f.read()
            
            # 替换模板变量
            config = self._replace_variables(template_content, bot_config)
            
            # 验证JSON格式
            json.loads(config)
            
            return config
            
        except Exception as e:
            logger.error(f"生成配置失败: {e}")
            raise
    
    def _replace_variables(self, config_str: str, variables: Dict[str, Any]) -> str:
        """替换配置中的变量"""
        for key, value in variables.items():
            placeholder = f"{{{{{key}}}}}"
            if isinstance(value, list):
                # 处理列表类型
                value_str = json.dumps(value)
            elif isinstance(value, str):
                # 检查是否已经是JSON格式的字符串
                if key in ["CORS_ORIGINS", "TRADING_PAIRS"]:
                    # 这些字段已经是JSON字符串，直接使用
                    value_str = value
                else:
                    # 处理普通字符串类型，直接替换，不添加引号
                    value_str = value
            else:
                # 处理其他类型
                value_str = str(value)
            
            config_str = config_str.replace(placeholder, value_str)
        
        return config_str
    
    def save_config(self, config_content: str, output_path: str) -> bool:
        """保存配置文件"""
        try:
            # 确保目录存在
            os.makedirs(os.path.dirname(output_path), exist_ok=True)
            
            # 保存配置文件
            with open(output_path, "w") as f:
                f.write(config_content)
            
            logger.info(f"配置文件已保存: {output_path}")
            return True
            
        except Exception as e:
            logger.error(f"保存配置文件失败: {e}")
            return False
    
    def generate_bot_config(
        self, 
        user_id: str,
        bot_id: str,
        exchange: str = "binance",
        trading_pairs: list = None,
        strategy: str = "SampleStrategy",
        max_open_trades: int = 3,
        stake_amount: float = 100,
        dry_run: bool = True,
        dry_run_wallet: float = 1000
    ) -> str:
        """生成机器人配置"""
        if trading_pairs is None:
            trading_pairs = ["BTC/USDT", "ETH/USDT"]
        
        # 生成安全密钥
        jwt_secret = self._generate_jwt_secret(user_id, bot_id)
        api_password = self._generate_api_password(user_id, bot_id)
        ws_token = self._generate_ws_token(user_id, bot_id)
        
        # 准备配置变量
        config_vars = {
            "JWT_SECRET": jwt_secret,
            "CORS_ORIGINS": json.dumps(["http://localhost:3000", "http://localhost:3001"]),
            "API_USERNAME": f"user_{user_id}",
            "API_PASSWORD": api_password,
            "WS_TOKEN": ws_token,
            "BOT_NAME": f"Bot-{bot_id}",
            "EXCHANGE": exchange,
            "TRADING_PAIRS": json.dumps(trading_pairs),
            "STRATEGY": strategy,
            "MAX_OPEN_TRADES": max_open_trades,
            "STAKE_AMOUNT": stake_amount,
            "DRY_RUN": str(dry_run).lower(),
            "DRY_RUN_WALLET": dry_run_wallet
        }
        
        return self.generate_config(config_vars)
    
    def _generate_jwt_secret(self, user_id: str, bot_id: str) -> str:
        """生成JWT密钥"""
        import secrets
        return secrets.token_urlsafe(32)
    
    def _generate_api_password(self, user_id: str, bot_id: str) -> str:
        """生成API密码"""
        import secrets
        return secrets.token_urlsafe(16)
    
    def _generate_ws_token(self, user_id: str, bot_id: str) -> str:
        """生成WebSocket令牌"""
        import secrets
        return secrets.token_urlsafe(24)
