# Freqtrade 国际化指南 / Internationalization Guide

本指南介绍如何在 Freqtrade 中使用国际化（i18n）功能。

This guide explains how to use internationalization (i18n) features in Freqtrade.

## 🌍 支持的语言 / Supported Languages

目前 Freqtrade 支持以下语言：
Currently, Freqtrade supports the following languages:

- **English** (en) - 默认语言 / Default language
- **简体中文** (zh_CN) - Simplified Chinese

## ⚙️ 配置语言 / Language Configuration

### 1. 配置文件设置 / Configuration File Setting

在 `config.json` 中添加语言设置：
Add language setting to your `config.json`:

```json
{
    "language": "zh_CN",
    "api_server": {
        "enabled": true,
        "listen_ip_address": "0.0.0.0",
        "listen_port": 8080,
        "multi_user_mode": true
    }
}
```

### 2. 支持的语言代码 / Supported Language Codes

- `en` - English (默认 / Default)
- `zh_CN` - 简体中文 / Simplified Chinese

### 3. 自动检测 / Auto Detection

如果未在配置中指定语言，Freqtrade 将：
If no language is specified in config, Freqtrade will:

1. 检测系统语言 / Detect system language
2. 如果系统语言不受支持，回退到英文 / Fall back to English if system language is unsupported

## 🚀 使用示例 / Usage Examples

### 命令行工具 / Command Line Tools

使用中文界面的多用户管理：
Using multi-user management with Chinese interface:

```bash
# 初始化多用户系统（中文输出）
freqtrade multi-user init --config config_i18n_example.json --username admin --password 123456

# 创建新用户（中文输出）
freqtrade multi-user create-user --config config_i18n_example.json --username trader1 --password 123456

# 列出所有用户（中文输出）
freqtrade multi-user list-users --config config_i18n_example.json
```

### 演示脚本 / Demo Script

运行多用户系统演示（中文界面）：
Run multi-user system demo (Chinese interface):

```bash
python demo_multi_user.py
```

## 🔧 开发者指南 / Developer Guide

### 添加新的可翻译字符串 / Adding New Translatable Strings

1. 在代码中使用翻译函数：
   Use translation functions in your code:

```python
from freqtrade.i18n import _, ngettext

# 简单翻译 / Simple translation
message = _("User created successfully")

# 复数翻译 / Plural translation  
message = ngettext("1 user found", "{} users found", count).format(count)
```

2. 提取翻译字符串：
   Extract translatable strings:

```bash
python manage_translations.py extract
```

3. 更新翻译文件：
   Update translation files:

```bash
python manage_translations.py update
```

4. 编辑翻译文件：
   Edit translation files:

```
freqtrade/translations/zh_CN/LC_MESSAGES/freqtrade.po
```

5. 编译翻译：
   Compile translations:

```bash
python manage_translations.py compile
```

### 添加新语言 / Adding New Languages

1. 初始化新语言：
   Initialize new language:

```bash
python manage_translations.py init --locale ja  # 日语 / Japanese
python manage_translations.py init --locale ko  # 韩语 / Korean
```

2. 翻译消息文件：
   Translate message files:

编辑 `freqtrade/translations/<locale>/LC_MESSAGES/freqtrade.po`

3. 编译翻译：
   Compile translations:

```bash
python manage_translations.py compile
```

4. 更新语言检测逻辑：
   Update language detection logic:

在 `freqtrade/i18n.py` 的 `detect_system_locale()` 函数中添加新语言映射。

## 📁 文件结构 / File Structure

```
freqtrade/
├── i18n.py                          # 核心国际化模块 / Core i18n module
├── config_i18n.py                   # 配置集成 / Configuration integration
├── translations/                     # 翻译文件目录 / Translations directory
│   ├── messages.pot                  # 翻译模板 / Translation template
│   ├── en/                          # 英语翻译 / English translations
│   │   └── LC_MESSAGES/
│   │       ├── freqtrade.po
│   │       └── messages.mo
│   └── zh_CN/                       # 中文翻译 / Chinese translations
│       └── LC_MESSAGES/
│           ├── freqtrade.po
│           └── messages.mo
├── babel.cfg                        # Babel 配置 / Babel configuration
├── manage_translations.py           # 翻译管理脚本 / Translation management
└── config_i18n_example.json        # 示例配置 / Example configuration
```

## 🐛 故障排除 / Troubleshooting

### 翻译不显示 / Translations Not Showing

1. 检查配置文件中的语言设置
   Check language setting in configuration file

2. 确保翻译文件已编译：
   Ensure translation files are compiled:

```bash
python manage_translations.py compile
```

3. 重启 Freqtrade 服务
   Restart Freqtrade service

### 添加依赖包 / Installing Dependencies

如果遇到缺少 babel 的错误：
If you encounter missing babel errors:

```bash
pip install babel flufl.i18n
```

## 🤝 贡献翻译 / Contributing Translations

欢迎贡献新语言或改进现有翻译！
Contributions for new languages or improvements to existing translations are welcome!

1. Fork 项目 / Fork the project
2. 添加或更新翻译文件 / Add or update translation files
3. 测试翻译效果 / Test translations
4. 提交 Pull Request / Submit Pull Request

## 📞 支持 / Support

如有问题或建议，请：
For questions or suggestions, please:

1. 查阅此文档 / Check this documentation
2. 查看示例配置 / Review example configuration
3. 运行演示脚本 / Run demo script
4. 提交 Issue 到 GitHub / Submit GitHub Issue

---

**实现状态**: ✅ 功能完整 / Feature Complete  
**版本**: Freqtrade i18n v1.0  
**更新时间**: 2025年9月19日 / Updated: September 19, 2025
