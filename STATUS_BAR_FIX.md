# 状态栏颜色返回修复

## 问题描述

从其他屏幕返回菜单屏幕时，状态栏的颜色没有正确变回深色，导致状态栏图标在浅色背景下不可见。

## 根本原因

1. **缺乏统一管理**：各个屏幕的状态栏设置不一致
2. **返回时未重置**：从子屏幕返回时没有重新设置主屏幕的状态栏
3. **状态栏设置分散**：状态栏设置代码分散在各个屏幕中，难以维护

## 解决方案

### 🔧 技术实现

#### 1. 创建统一的状态栏管理器

**文件**: `lib/utils/status_bar_manager.dart`

```dart
class StatusBarManager {
  /// 设置主屏幕状态栏（根据屏幕大小自适应）
  static void setHomeScreenStatusBar(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 768;

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: isSmallScreen ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: isSmallScreen ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isSmallScreen ? Colors.white : const Color(0xFF667EEA),
        systemNavigationBarIconBrightness: isSmallScreen ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// 设置游戏屏幕状态栏（深色背景，浅色图标）
  static void setGameScreenStatusBar() { /* ... */ }
  
  /// 设置学习屏幕状态栏（深色背景，浅色图标）
  static void setLearningScreenStatusBar() { /* ... */ }
  
  /// 设置设置屏幕状态栏（深色背景，浅色图标）
  static void setSettingsScreenStatusBar() { /* ... */ }
  
  /// 延迟设置状态栏（确保在布局完成后执行）
  static void setStatusBarDelayed(VoidCallback statusBarSetter) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      statusBarSetter();
    });
  }
}
```

#### 2. 更新主屏幕状态栏管理

**文件**: `lib/screens/home_screen.dart`

```dart
// 简化状态栏更新方法
void _updateStatusBar() {
  if (!mounted) return;
  StatusBarManager.setHomeScreenStatusBar(context);
}

// 在所有导航返回时更新状态栏
Navigator.push(context, route).then((_) => _updateStatusBar());
```

#### 3. 在各个屏幕设置对应的状态栏

**游戏屏幕** (`lib/widgets/chess_board.dart`):
```dart
@override
Widget build(BuildContext context) {
  // 设置游戏屏幕状态栏
  StatusBarManager.setStatusBarDelayed(() {
    StatusBarManager.setGameScreenStatusBar();
  });
  
  return FutureBuilder<bool>(/* ... */);
}
```

**学习屏幕** (`lib/screens/learning_screen.dart`):
```dart
@override
Widget build(BuildContext context) {
  // 设置学习屏幕状态栏
  StatusBarManager.setStatusBarDelayed(() {
    StatusBarManager.setLearningScreenStatusBar();
  });
  
  return BlocProvider(/* ... */);
}
```

**设置屏幕** (`lib/screens/settings_screen.dart`):
```dart
@override
Widget build(BuildContext context) {
  // 设置设置屏幕状态栏
  StatusBarManager.setStatusBarDelayed(() {
    StatusBarManager.setSettingsScreenStatusBar();
  });
  
  return Scaffold(/* ... */);
}
```

### 📱 状态栏配色方案

#### 主屏幕（自适应）
- **小屏幕** (< 768px): 深色图标 + 白色背景
- **大屏幕** (≥ 768px): 浅色图标 + 渐变背景

#### 子屏幕（统一深色主题）
- **游戏屏幕**: 浅色图标 + 深色背景
- **学习屏幕**: 浅色图标 + 深色背景  
- **设置屏幕**: 浅色图标 + 深色背景

### 🔄 工作流程

1. **进入子屏幕**: 自动设置对应的状态栏样式
2. **返回主屏幕**: 通过 `.then((_) => _updateStatusBar())` 重新设置主屏幕状态栏
3. **延迟执行**: 使用 `setStatusBarDelayed` 确保在布局完成后设置

### ✅ 修复效果

#### 修复前：
- ❌ 从游戏屏幕返回主屏幕，状态栏图标可能不可见
- ❌ 状态栏设置不一致，用户体验差
- ❌ 代码分散，难以维护

#### 修复后：
- ✅ 返回主屏幕时状态栏正确重置为深色图标
- ✅ 各屏幕状态栏样式统一且合适
- ✅ 集中管理，易于维护和扩展
- ✅ 支持响应式设计，适配不同屏幕尺寸

### 🧪 测试验证

创建了 `test/status_bar_manager_test.dart` 验证：
- ✅ 状态栏管理器方法正常执行
- ✅ 主屏幕状态栏设置正常
- ✅ 延迟设置机制正常工作

### 🎯 技术亮点

1. **统一管理**: 所有状态栏设置集中在一个管理器中
2. **响应式设计**: 主屏幕根据屏幕大小自适应状态栏样式
3. **延迟执行**: 确保状态栏设置在布局完成后执行
4. **生命周期集成**: 与 Flutter 的生命周期完美集成
5. **易于扩展**: 新增屏幕时只需添加对应的设置方法

这个修复不仅解决了状态栏颜色问题，还建立了一个可维护、可扩展的状态栏管理系统，为未来的功能扩展奠定了基础。
