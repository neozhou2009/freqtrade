# 📚 i18n 文档更新说明

## ✅ 完成的工作

已将完整的 i18n（国际化）实现细节整理为正式文档，并集成到 Freqtrade 文档系统中。

## 📝 新增文件

### 1. 主文档文件
**路径**: `/docs/internationalization.md`

**内容包含**:
- i18n 系统概述
- 支持的语言列表
- 配置方法和自动检测
- 使用指南（CLI、Python代码、REST API）
- 翻译覆盖范围对照表
- 开发者指南（文件结构、翻译工作流程）
- 添加新语言的步骤
- 前端集成方案（Vue.js/Nuxt 3）
- 最佳实践和性能优化
- 故障排除指南
- 贡献翻译的方法

**特点**:
- ✅ 符合 MkDocs 文档规范
- ✅ 包含完整的使用示例
- ✅ 中英文对照表格
- ✅ 详细的开发者指南
- ✅ 实用的代码示例
- ✅ 清晰的工作流程图

### 2. 文档导航更新
**文件**: `/mkdocs.yml`

**修改内容**:
```yaml
- Advanced Topics:
    ...
    - SQL Cheat-sheet: sql_cheatsheet.md
    - Internationalization (i18n): internationalization.md  # 新增
```

**位置**: Advanced Topics 部分的最后一项，位于 FAQ 之前

## 📋 文档结构

```
docs/
├── internationalization.md          # 新增的 i18n 文档
├── configuration.md
├── bot-usage.md
├── rest-api.md
└── ...
```

在 MkDocs 文档中显示为:
```
Freqtrade 文档
├── Home
├── Configuration
├── ...
├── Advanced Topics
│   ├── Advanced Post-installation Tasks
│   ├── ...
│   ├── SQL Cheat-sheet
│   └── Internationalization (i18n)  ← 新增
├── FAQ
└── Contributors Guide
```

## 📖 文档内容概览

### 章节结构

1. **Overview** - 系统概述和特性介绍
2. **Supported Languages** - 支持的语言列表
3. **Configuration** - 配置方法（自动检测、手动设置）
4. **Usage** - 使用指南
   - Command Line Interface
   - In Python Code
   - REST API
5. **Translation Coverage** - 翻译覆盖范围对照表
6. **Developer Guide** - 开发者指南
   - File Structure
   - Adding Translations
   - Translation Workflow
   - Adding New Languages
7. **Frontend Integration** - 前端集成（Vue.js/Nuxt 3）
8. **Best Practices** - 最佳实践
9. **Performance** - 性能优化说明
10. **Troubleshooting** - 故障排除
11. **Contributing** - 如何贡献翻译
12. **API Reference** - API参考
13. **Resources** - 相关资源链接

### 重点内容

#### 配置示例
```json
{
    "language": "zh_CN",
    "api_server": {
        "enabled": true,
        "listen_ip_address": "0.0.0.0",
        "listen_port": 8080
    }
}
```

#### 代码使用示例
```python
from freqtrade.i18n import _, ngettext

# Simple translation
message = _("User created successfully")

# Plural translation
message = ngettext("1 trade", "{} trades", count)
```

#### 翻译工作流程
```
Write Code → Extract → Update → Translate → Compile → Load
   _()    →  extract → update →  edit.po → compile →  app
```

#### API端点
- `GET /api/v1/i18n/translations` - 获取所有翻译
- `GET /api/v1/i18n/translations/{locale}` - 获取特定语言

## 🎯 文档特点

### 1. 用户友好
- 清晰的配置步骤
- 详细的使用示例
- 中英文对照表格
- 常见问题解答

### 2. 开发者友好
- 完整的文件结构说明
- 详细的工作流程图
- 代码示例丰富
- 最佳实践指南

### 3. 维护友好
- 标准 Markdown 格式
- 符合 MkDocs 规范
- 易于更新和扩展
- 版本信息清晰

## 🔗 相关文件

已有的 i18n 相关文档：
- `/I18N_IMPLEMENTATION_SUMMARY.md` - 实现总结（项目根目录）
- `/I18N_GUIDE.md` - 使用指南（项目根目录）
- `/I18N_DETAILED_ANALYSIS.md` - 详细分析（项目根目录）

新增的官方文档：
- `/docs/internationalization.md` - 正式文档（docs目录）
- `/mkdocs.yml` - 文档导航配置（已更新）

## 📊 对比说明

| 文件 | 位置 | 用途 | 受众 |
|------|------|------|------|
| I18N_IMPLEMENTATION_SUMMARY.md | 根目录 | 项目实现总结 | 开发团队 |
| I18N_GUIDE.md | 根目录 | 双语使用指南 | 中英文用户 |
| I18N_DETAILED_ANALYSIS.md | 根目录 | 深入技术分析 | 技术人员 |
| **docs/internationalization.md** | **docs目录** | **官方用户文档** | **最终用户** |

**新文档特点**：
- ✅ 集成到官方文档系统
- ✅ 通过 MkDocs 构建和发布
- ✅ 遵循项目文档风格
- ✅ 面向最终用户和贡献者
- ✅ 包含完整的使用和开发指南

## 🚀 如何查看文档

### 本地构建文档

```bash
# 安装依赖
pip install mkdocs mkdocs-material

# 启动本地文档服务器
mkdocs serve

# 访问
http://127.0.0.1:8000/
```

### 文档位置

在导航中找到：
```
Advanced Topics → Internationalization (i18n)
```

## ✅ 验证清单

- [x] 文档文件已创建：`docs/internationalization.md`
- [x] mkdocs.yml 已更新，添加导航链接
- [x] 文档内容完整，包含所有必要章节
- [x] 代码示例正确且可执行
- [x] 链接和引用正确
- [x] 格式符合 MkDocs 规范
- [x] 中英文术语对照表完整
- [x] 包含故障排除指南
- [x] 包含贡献指南

## 📌 注意事项

1. **文档语言**: 主文档使用英文，包含中英文对照
2. **维护**: 当 i18n 功能更新时，需同步更新此文档
3. **位置**: 放在 Advanced Topics 下，因为是高级功能
4. **格式**: 遵循 Freqtrade 文档的统一格式和风格

## 🔄 后续工作

当 i18n 功能有以下更新时，需要更新文档：
- ✅ 添加新语言支持
- ✅ 新增 API 端点
- ✅ 翻译覆盖范围变化
- ✅ 工作流程改进
- ✅ 前端集成完成

## 📝 总结

已成功将 Freqtrade 的 i18n 实现细节整理为规范的官方文档，并集成到文档系统中。文档内容全面、结构清晰、易于维护，为用户和开发者提供了完整的国际化使用和开发指南。

---

**创建时间**: 2025年1月2日  
**文档版本**: v1.0  
**状态**: ✅ 完成并集成到文档系统

