/// V8Ray 响应式布局工具
///
/// 提供响应式布局辅助功能

import 'package:flutter/material.dart';

/// 屏幕尺寸断点
class Breakpoints {
  Breakpoints._();

  /// 手机（小屏）
  static const double mobile = 600;

  /// 平板（中屏）
  static const double tablet = 900;

  /// 桌面（大屏）
  static const double desktop = 1200;

  /// 超大屏
  static const double ultraWide = 1800;
}

/// 设备类型
enum DeviceType {
  /// 手机
  mobile,

  /// 平板
  tablet,

  /// 桌面
  desktop,

  /// 超大屏
  ultraWide,
}

/// 响应式工具类
class Responsive {
  final BuildContext context;

  Responsive(this.context);

  /// 获取屏幕宽度
  double get width => MediaQuery.of(context).size.width;

  /// 获取屏幕高度
  double get height => MediaQuery.of(context).size.height;

  /// 获取设备类型
  DeviceType get deviceType {
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else if (width < Breakpoints.desktop) {
      return DeviceType.desktop;
    } else {
      return DeviceType.ultraWide;
    }
  }

  /// 是否是手机
  bool get isMobile => width < Breakpoints.mobile;

  /// 是否是平板
  bool get isTablet =>
      width >= Breakpoints.mobile && width < Breakpoints.tablet;

  /// 是否是桌面
  bool get isDesktop => width >= Breakpoints.tablet;

  /// 是否是超大屏
  bool get isUltraWide => width >= Breakpoints.ultraWide;

  /// 根据屏幕宽度返回值
  T valueWhen<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? ultraWide,
  }) {
    if (width >= Breakpoints.ultraWide && ultraWide != null) {
      return ultraWide;
    } else if (width >= Breakpoints.desktop && desktop != null) {
      return desktop;
    } else if (width >= Breakpoints.tablet && tablet != null) {
      return tablet;
    } else if (width >= Breakpoints.mobile && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// 根据设备类型返回值
  T deviceValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? ultraWide,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.ultraWide:
        return ultraWide ?? desktop ?? tablet ?? mobile;
    }
  }

  /// 获取响应式内边距
  EdgeInsets get padding {
    return EdgeInsets.all(valueWhen(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    ));
  }

  /// 获取响应式列数
  int get columns {
    return valueWhen(
      mobile: 1,
      tablet: 2,
      desktop: 3,
      ultraWide: 4,
    );
  }

  /// 获取响应式最大宽度
  double get maxWidth {
    return valueWhen(
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
      ultraWide: 1600,
    );
  }
}

/// 响应式构建器
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, DeviceType deviceType) builder;

  const ResponsiveBuilder({
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    return builder(context, responsive.deviceType);
  }
}

/// 响应式布局
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  final Widget? ultraWide;

  const ResponsiveLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    this.ultraWide,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);

    return responsive.deviceValue(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      ultraWide: ultraWide,
    );
  }
}

/// 响应式网格
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    required this.children,
    this.spacing = 16.0,
    this.runSpacing = 16.0,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final columns = responsive.valueWhen(
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: spacing,
        mainAxisSpacing: runSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// 响应式容器
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final bool center;

  const ResponsiveContainer({
    required this.child,
    this.maxWidth,
    this.padding,
    this.center = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive(context);
    final effectiveMaxWidth = maxWidth ?? responsive.maxWidth;
    final effectivePadding = padding ?? responsive.padding;

    Widget content = Container(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      padding: effectivePadding,
      child: child,
    );

    if (center) {
      content = Center(child: content);
    }

    return content;
  }
}

/// 响应式间距
class ResponsiveSpacing {
  final BuildContext context;

  ResponsiveSpacing(this.context);

  /// 小间距
  double get small {
    return Responsive(context).valueWhen(
      mobile: 8.0,
      tablet: 12.0,
      desktop: 16.0,
    );
  }

  /// 中等间距
  double get medium {
    return Responsive(context).valueWhen(
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// 大间距
  double get large {
    return Responsive(context).valueWhen(
      mobile: 24.0,
      tablet: 32.0,
      desktop: 48.0,
    );
  }
}

