import 'package:flutter/material.dart';

/// 自定义页面转换动画
class CustomPageTransitions {
  /// 滑入动画 - 从右侧滑入
  static PageRouteBuilder<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// 滑入动画 - 从左侧滑入
  static PageRouteBuilder<T> slideFromLeft<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// 滑入动画 - 从底部滑入
  static PageRouteBuilder<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// 淡入动画
  static PageRouteBuilder<T> fadeIn<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// 缩放淡入动画
  static PageRouteBuilder<T> scaleIn<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        
        var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        
        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return ScaleTransition(
          scale: animation.drive(scaleTween),
          child: FadeTransition(
            opacity: animation.drive(fadeTween),
            child: child,
          ),
        );
      },
    );
  }

  /// 主题一致的页面转换 - 与首页菜单按钮动画保持一致
  static PageRouteBuilder<T> themeConsistent<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 500),
      reverseTransitionDuration: const Duration(milliseconds: 400),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // 组合动画：滑入 + 缩放 + 淡入
        const slideBegin = Offset(0.0, 0.3);
        const slideEnd = Offset.zero;
        const curve = Curves.easeOutCubic;

        var slideTween = Tween(begin: slideBegin, end: slideEnd).chain(
          CurveTween(curve: curve),
        );

        var scaleTween = Tween(begin: 0.9, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(slideTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: FadeTransition(
              opacity: animation.drive(fadeTween),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// 扩展Navigator，提供便捷的页面转换方法
extension NavigatorExtensions on NavigatorState {
  /// 使用主题一致的转换动画推送页面
  Future<T?> pushWithThemeTransition<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.themeConsistent<T>(page));
  }

  /// 使用滑入动画推送页面
  Future<T?> pushWithSlide<T extends Object?>(Widget page, {SlideDirection direction = SlideDirection.right}) {
    PageRouteBuilder<T> route;
    switch (direction) {
      case SlideDirection.right:
        route = CustomPageTransitions.slideFromRight<T>(page);
        break;
      case SlideDirection.left:
        route = CustomPageTransitions.slideFromLeft<T>(page);
        break;
      case SlideDirection.bottom:
        route = CustomPageTransitions.slideFromBottom<T>(page);
        break;
    }
    return push<T>(route);
  }

  /// 使用淡入动画推送页面
  Future<T?> pushWithFade<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.fadeIn<T>(page));
  }

  /// 使用缩放动画推送页面
  Future<T?> pushWithScale<T extends Object?>(Widget page) {
    return push<T>(CustomPageTransitions.scaleIn<T>(page));
  }
}

/// 滑动方向枚举
enum SlideDirection {
  right,
  left,
  bottom,
}
