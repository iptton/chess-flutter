# Stockfish.js 更新说明

## 更新内容

本次更新将 Stockfish WebAssembly 文件替换为 lichess-org/stockfish.js 版本，以支持 Chrome 浏览器的 WASM 多线程功能。

## 更新的文件

### 1. Stockfish 核心文件
- `web/stockfish/stockfish.js` - 主要的 Stockfish JavaScript 文件
- `web/stockfish/stockfish.wasm` - WebAssembly 二进制文件
- `web/stockfish/stockfish.worker.js` - Web Worker 文件

这些文件来自 lichess-org/stockfish.js 项目的最新 release (ddugovic-250718)。

### 2. HTTP 头配置文件
- `web/.htaccess` - Apache 服务器配置文件
- `web/_headers` - Netlify 等静态托管服务配置文件

这些文件设置了必要的 HTTP 头来支持 SharedArrayBuffer 和 Atomics，这是 Chrome 中 WASM 多线程所必需的。

### 3. HTML 更新
- `web/index.html` - 添加了必要的 meta 标签

## 必要的 HTTP 头

为了在 Chrome 中启用 WASM 多线程功能，需要设置以下 HTTP 头：

```
Cross-Origin-Embedder-Policy: require-corp
Cross-Origin-Opener-Policy: same-origin
```

对于 WASM 和 JS 文件，还需要：

```
Cross-Origin-Resource-Policy: cross-origin
Access-Control-Allow-Origin: *
```

## 部署说明

### Apache 服务器
如果使用 Apache 服务器，`.htaccess` 文件会自动设置必要的头。确保服务器启用了 `mod_headers` 模块。

### Nginx 服务器
如果使用 Nginx，需要在服务器配置中添加：

```nginx
location / {
    add_header Cross-Origin-Embedder-Policy require-corp;
    add_header Cross-Origin-Opener-Policy same-origin;
}

location ~* \.(wasm|js)$ {
    add_header Cross-Origin-Resource-Policy cross-origin;
    add_header Access-Control-Allow-Origin *;
}
```

### 静态托管服务
- **Netlify**: `_headers` 文件会自动应用
- **Vercel**: 需要在 `vercel.json` 中配置头
- **GitHub Pages**: 不支持自定义头，可能无法使用多线程功能

## 版本信息

- **Stockfish 版本**: ddugovic-250718
- **来源**: https://github.com/lichess-org/stockfish.js
- **支持的功能**: 
  - WebAssembly 多线程
  - SharedArrayBuffer
  - Atomics
  - 多变体象棋支持

## 兼容性

### 支持的浏览器
- Chrome 68+ (需要正确的 HTTP 头)
- Firefox 79+
- Safari 15.2+
- Edge 79+

### 注意事项
1. **本地开发**: 在本地开发时，需要使用 HTTPS 或者 localhost 来测试多线程功能
2. **跨域**: 确保所有资源都设置了正确的 CORS 头
3. **服务器配置**: 必须正确配置 HTTP 头，否则多线程功能将不可用

## 测试

要测试多线程功能是否正常工作，可以在浏览器控制台中检查：

```javascript
// 检查 SharedArrayBuffer 是否可用
console.log('SharedArrayBuffer available:', typeof SharedArrayBuffer !== 'undefined');

// 检查 Atomics 是否可用
console.log('Atomics available:', typeof Atomics !== 'undefined');
```

如果两者都返回 `true`，则多线程功能应该可以正常工作。

## 性能提升

使用多线程版本的 Stockfish 可以带来以下性能提升：
- 更快的棋局分析
- 更深的搜索深度
- 更好的用户体验（UI 不会被阻塞）
- 支持更高级的 AI 设置

## 故障排除

### 问题：SharedArrayBuffer 不可用
**解决方案**: 检查 HTTP 头设置，确保 `Cross-Origin-Embedder-Policy` 和 `Cross-Origin-Opener-Policy` 正确设置。

### 问题：WASM 文件加载失败
**解决方案**: 检查 CORS 设置，确保 WASM 文件可以被正确加载。

### 问题：Worker 无法启动
**解决方案**: 检查 `stockfish.worker.js` 文件是否可以访问，并且设置了正确的 CORS 头。

## 更多信息

- [lichess-org/stockfish.js GitHub 仓库](https://github.com/lichess-org/stockfish.js)
- [WebAssembly 多线程文档](https://web.dev/webassembly-threads/)
- [SharedArrayBuffer 安全要求](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/SharedArrayBuffer#security_requirements)
