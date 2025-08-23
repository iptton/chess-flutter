# Stockfish WebAssembly 包更新

## 概述

本文档记录将 Stockfish WebAssembly 文件改为从 https://npmjs.com/package/stockfish.wasm 获取的更新过程。

## 更新内容

### 1. package.json 更新

更新了项目的 `package.json` 文件以包含完整的项目信息和自动化脚本：

```json
{
  "name": "flutter-chess-web",
  "version": "1.0.0",
  "description": "Flutter Chess Game with Stockfish WebAssembly",
  "dependencies": {
    "stockfish.wasm": "^0.10.0"
  },
  "scripts": {
    "postinstall": "npm run copy-stockfish",
    "copy-stockfish": "cp node_modules/stockfish.wasm/stockfish.js web/stockfish/ && cp node_modules/stockfish.wasm/stockfish.wasm web/stockfish/ && cp node_modules/stockfish.wasm/stockfish.worker.js web/stockfish/"
  }
}
```

### 2. 自动化文件拷贝

- 添加了 `postinstall` 脚本，在安装依赖后自动拷贝 Stockfish 文件
- 添加了 `copy-stockfish` 脚本用于手动拷贝文件

### 3. 官方 Stockfish WebAssembly 文件

从 npmjs.com/package/stockfish.wasm 获取的官方文件：

- `stockfish.js` (29.8KB) - 主引擎文件
- `stockfish.wasm` (339.2KB) - WebAssembly 二进制文件  
- `stockfish.worker.js` (3.1KB) - Web Worker 脚本

这些文件大小符合官方规范要求。

## 使用方法

### 安装和更新

1. 安装依赖（自动拷贝文件）：
   ```bash
   npm install
   ```

2. 手动拷贝文件（如需要）：
   ```bash
   npm run copy-stockfish
   ```

### 验证安装

检查 `web/stockfish/` 目录应包含以下文件：
- stockfish.js
- stockfish.wasm  
- stockfish.worker.js

## 技术规范

### Web 端配置要求

确保 `web/index.html` 包含必要的 HTTP 头支持：

```html
<!-- WebAssembly multithreading support headers -->
<meta http-equiv="Cross-Origin-Embedder-Policy" content="require-corp">
<meta http-equiv="Cross-Origin-Opener-Policy" content="same-origin">

<!-- Stockfish WebAssembly Support -->
<script src="stockfish/stockfish.js"></script>
```

### SharedArrayBuffer 支持

- 官方 Stockfish WebAssembly 引擎需要 SharedArrayBuffer 支持
- 当 SharedArrayBuffer 不可用时，系统会自动回退到简化的 AI 引擎
- 回退引擎使用 chess 包生成合法移动，保证游戏功能正常

## 兼容性

- 完全兼容 UCI (Universal Chess Interface) 协议
- 支持多线程 WebAssembly（如果浏览器支持）
- 提供回退方案确保在受限环境中也能正常工作

## 优势

1. **官方支持**: 使用 npmjs.com 上的官方 stockfish.wasm 包
2. **自动化**: npm 脚本自动处理文件拷贝
3. **标准化**: 符合 Web 端 AI 引擎实现规范
4. **稳定性**: 官方包提供更好的稳定性和更新支持
5. **兼容性**: 完整的 UCI 协议支持

## 下一步

- 建议在部署时验证所有文件都正确拷贝到了 web/stockfish/ 目录
- 可以考虑添加文件完整性检查脚本
- 监控官方包的更新以获取性能和功能改进