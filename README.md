# testflutter

一个基于Flutter框架开发的跨平台国际象棋游戏应用，支持人机对战、游戏复盘等功能。

## 功能特性

- 🎯 **人机对战**: 集成Stockfish WebAssembly引擎，支持多难度级别AI对战
- 🔄 **游戏复盘**: 完整的对局历史记录和回放功能
- 🎨 **自定义主题**: 多种棋盘主题和界面配色方案
- 🌐 **跨平台支持**: Android、iOS、macOS、Web、OHOS等多平台
- 🔧 **BLoC架构**: 使用BLoC模式进行状态管理

## 技术栈

- **前端**: Flutter框架
- **状态管理**: BLoC模式
- **AI引擎**: Stockfish WebAssembly (官方包)
- **Web支持**: SharedArrayBuffer + WebAssembly
- **本地化**: Flutter内置l10n支持

## Web端AI引擎

项目使用官方的 [stockfish.wasm](https://npmjs.com/package/stockfish.wasm) 包提供Web端AI功能：

- **官方支持**: 来自npmjs.com的官方Stockfish WebAssembly包
- **完整UCI协议**: 支持标准的Universal Chess Interface
- **智能回退**: 当WebAssembly不可用时自动使用简化AI引擎
- **多线程支持**: 支持SharedArrayBuffer多线程计算

### Web端配置要求

```html
<!-- 支持WebAssembly多线程 -->
<meta http-equiv="Cross-Origin-Embedder-Policy" content="require-corp">
<meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin">
```

## 快速开始

### 环境要求

- Flutter SDK (最新稳定版)
- Node.js (用于Web端依赖管理)
- Android Studio / VS Code

### 安装依赖

1. 安装Flutter依赖：
```bash
flutter pub get
```

2. 安装Web端Stockfish依赖：
```bash
npm install
```

### 运行项目

#### 移动端
```bash
flutter run
```

#### Web端
```bash
flutter run -d web-server --web-port 8080
```

#### 构建发布版本
```bash
# Web版本
flutter build web --release

# Android版本
flutter build apk --release

# iOS版本
flutter build ios --release
```

### 验证安装

运行验证脚本检查所有组件：
```bash
./verify_stockfish.sh
```

## 项目结构

```
lib/
├── blocs/          # BLoC状态管理
├── models/         # 数据模型
├── screens/        # 页面视图
├── services/       # 业务服务
├── utils/          # 工具类
├── widgets/        # 自定义组件
└── main.dart       # 入口文件

web/
├── stockfish/      # Stockfish WebAssembly文件
├── index.html      # Web入口
└── manifest.json   # Web应用清单

test/
├── *_test.dart     # 单元测试
└── integration_test/ # 集成测试
```

## 开发指南

### 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定测试
flutter test test/stockfish_adapter_test.dart
```

### 调试Web端AI

1. 打开浏览器开发者工具
2. 查看控制台输出中的 "StockfishWebAdapter" 日志
3. 检查SharedArrayBuffer支持状态
4. 验证WebAssembly文件加载情况

### 更新Stockfish引擎

```bash
# 更新到最新版本
npm update stockfish.wasm

# 重新拷贝文件
npm run copy-stockfish

# 重新构建
flutter build web
```

## 相关文档

- [Stockfish WebAssembly更新说明](STOCKFISH_WASM_UPDATE.md)
- [跨平台AI实现总结](AI_IMPLEMENTATION_SUMMARY.md)
- [Web端AI实现详解](WEB_AI_IMPLEMENTATION.md)

## 贡献

欢迎提交Issue和Pull Request来改进项目！
