#!/bin/bash

# Stockfish WebAssembly 验证脚本
# 用于验证从 npmjs.com/package/stockfish.wasm 集成的文件

echo "🚀 开始验证 Stockfish WebAssembly 集成..."

# 1. 检查 npm 包
echo "📦 检查 npm 包..."
if [ -f "package.json" ]; then
    echo "✅ package.json 存在"
    if grep -q "stockfish.wasm" package.json; then
        echo "✅ stockfish.wasm 依赖已配置"
    else
        echo "❌ stockfish.wasm 依赖未找到"
        exit 1
    fi
else
    echo "❌ package.json 不存在"
    exit 1
fi

# 2. 检查 node_modules 中的源文件
echo "📂 检查源文件..."
if [ -d "node_modules/stockfish.wasm" ]; then
    echo "✅ stockfish.wasm 包已安装"
    
    required_files=("stockfish.js" "stockfish.wasm" "stockfish.worker.js")
    for file in "${required_files[@]}"; do
        if [ -f "node_modules/stockfish.wasm/$file" ]; then
            echo "✅ 源文件 $file 存在"
        else
            echo "❌ 源文件 $file 缺失"
            exit 1
        fi
    done
else
    echo "❌ stockfish.wasm 包未安装"
    exit 1
fi

# 3. 检查 web 目录中的拷贝文件
echo "🌐 检查 Web 目录文件..."
if [ -d "web/stockfish" ]; then
    echo "✅ web/stockfish 目录存在"
    
    for file in "${required_files[@]}"; do
        if [ -f "web/stockfish/$file" ]; then
            size=$(stat -f%z "web/stockfish/$file" 2>/dev/null || stat -c%s "web/stockfish/$file" 2>/dev/null)
            echo "✅ Web 文件 $file 存在 (${size} bytes)"
        else
            echo "❌ Web 文件 $file 缺失"
            exit 1
        fi
    done
else
    echo "❌ web/stockfish 目录不存在"
    exit 1
fi

# 4. 检查构建目录中的文件
echo "🔨 检查构建文件..."
if [ -d "build/web/stockfish" ]; then
    echo "✅ build/web/stockfish 目录存在"
    
    for file in "${required_files[@]}"; do
        if [ -f "build/web/stockfish/$file" ]; then
            size=$(stat -f%z "build/web/stockfish/$file" 2>/dev/null || stat -c%s "build/web/stockfish/$file" 2>/dev/null)
            echo "✅ 构建文件 $file 存在 (${size} bytes)"
        else
            echo "⚠️  构建文件 $file 缺失（请运行 flutter build web）"
        fi
    done
else
    echo "⚠️  构建目录不存在（请运行 flutter build web）"
fi

# 5. 验证文件大小是否符合预期
echo "📏 验证文件大小..."
expected_sizes=(
    "stockfish.js:25000:35000"      # ~30KB
    "stockfish.wasm:300000:400000"  # ~340KB  
    "stockfish.worker.js:2000:5000" # ~3KB
)

for size_spec in "${expected_sizes[@]}"; do
    IFS=':' read -r filename min_size max_size <<< "$size_spec"
    
    if [ -f "web/stockfish/$filename" ]; then
        actual_size=$(stat -f%z "web/stockfish/$filename" 2>/dev/null || stat -c%s "web/stockfish/$filename" 2>/dev/null)
        
        if [ "$actual_size" -ge "$min_size" ] && [ "$actual_size" -le "$max_size" ]; then
            echo "✅ $filename 文件大小正常 (${actual_size} bytes)"
        else
            echo "⚠️  $filename 文件大小异常 (${actual_size} bytes, 期望 ${min_size}-${max_size})"
        fi
    fi
done

# 6. 检查 index.html 配置
echo "🔧 检查 Web 配置..."
if [ -f "web/index.html" ]; then
    if grep -q "stockfish/stockfish.js" web/index.html; then
        echo "✅ index.html 已配置 Stockfish 脚本"
    else
        echo "⚠️  index.html 未配置 Stockfish 脚本"
    fi
    
    if grep -q "Cross-Origin-Embedder-Policy" web/index.html; then
        echo "✅ SharedArrayBuffer 支持头已配置"
    else
        echo "⚠️  SharedArrayBuffer 支持头未配置"
    fi
else
    echo "❌ web/index.html 不存在"
    exit 1
fi

# 7. 运行测试
echo "🧪 运行相关测试..."
if flutter test test/stockfish_adapter_test.dart > /dev/null 2>&1; then
    echo "✅ Stockfish 适配器测试通过"
else
    echo "⚠️  Stockfish 适配器测试失败"
fi

echo ""
echo "🎉 Stockfish WebAssembly 集成验证完成！"
echo ""
echo "📝 要手动测试，请运行："
echo "   npm run copy-stockfish    # 拷贝文件"
echo "   flutter build web         # 构建项目"  
echo "   flutter run -d web-server # 启动开发服务器"
echo ""
echo "🌍 使用官方 stockfish.wasm 包：https://npmjs.com/package/stockfish.wasm"