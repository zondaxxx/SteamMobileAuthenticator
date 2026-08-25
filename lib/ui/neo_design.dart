import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class NeoColors {
  static const darkBackground = Color(0xff000000);
  static const darkBackgroundEnd = Color(0xff000000);
  static const darkPanel = Color(0xff04070a);
  static const darkPanelHigh = Color(0xff091018);
  static const darkBorder = Color(0xff173149);
  static const blue = Color(0xff43a9ff);
  static const cyan = Color(0xff5de4ff);
  static const violet = Color(0xff8d7dff);
  static const mint = Color(0xff54e0b0);
  static const amber = Color(0xffffc45c);
  static const danger = Color(0xffff6b7d);

  static const lightBackground = Color(0xffedf5fc);
  static const lightBackgroundEnd = Color(0xffdfeef9);
  static const lightPanel = Color(0xfff8fbff);
  static const lightPanelHigh = Color(0xffffffff);
  static const lightBorder = Color(0xffc9dbea);
}

ThemeData steamNeoTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? NeoColors.blue : const Color(0xff0877cc),
    onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xff123b60) : const Color(0xffd4ebff),
    onPrimaryContainer: dark
        ? const Color(0xffd9eeff)
        : const Color(0xff062f50),
    secondary: dark ? NeoColors.cyan : const Color(0xff007d95),
    onSecondary: dark ? const Color(0xff00252c) : Colors.white,
    secondaryContainer: dark
        ? const Color(0xff123946)
        : const Color(0xffc6f2fb),
    onSecondaryContainer: dark
        ? const Color(0xffd4f8ff)
        : const Color(0xff003640),
    tertiary: dark ? NeoColors.violet : const Color(0xff6752d7),
    onTertiary: Colors.white,
    tertiaryContainer: dark ? const Color(0xff2d2852) : const Color(0xffe8e2ff),
    onTertiaryContainer: dark
        ? const Color(0xffece8ff)
        : const Color(0xff281866),
    error: dark ? NeoColors.danger : const Color(0xffba1a34),
    onError: Colors.white,
    errorContainer: dark ? const Color(0xff421d29) : const Color(0xffffd9df),
    onErrorContainer: dark ? const Color(0xffffd9df) : const Color(0xff40000d),
    surface: dark ? NeoColors.darkPanel : NeoColors.lightPanel,
    onSurface: dark ? const Color(0xfff0f6ff) : const Color(0xff142435),
    surfaceContainerHighest: dark
        ? NeoColors.darkPanelHigh
        : const Color(0xffe3eef7),
    onSurfaceVariant: dark ? const Color(0xff98abc0) : const Color(0xff506477),
    outline: dark ? NeoColors.darkBorder : NeoColors.lightBorder,
    outlineVariant: dark ? const Color(0xff182d43) : const Color(0xffd5e3ee),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? const Color(0xffedf5ff) : const Color(0xff172637),
    onInverseSurface: dark ? const Color(0xff172637) : Colors.white,
    inversePrimary: dark ? const Color(0xff0069b8) : const Color(0xff8bccff),
  );
  final baseText = ThemeData(brightness: brightness).textTheme
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  final textTheme = baseText.copyWith(
    displaySmall: baseText.displaySmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    ),
    headlineLarge: baseText.headlineLarge?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
    ),
    headlineMedium: baseText.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    headlineSmall: baseText.headlineSmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.35,
    ),
    titleLarge: baseText.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
    ),
    titleMedium: baseText.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    labelLarge: baseText.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    textTheme: textTheme,
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: dark ? NeoColors.darkBackground : NeoColors.lightBackground,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: dark
          ? NeoColors.darkPanel.withValues(alpha: 0.92)
          : NeoColors.lightPanel.withValues(alpha: 0.92),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.7)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant.withValues(alpha: 0.8),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark
          ? NeoColors.darkPanelHigh.withValues(alpha: 0.72)
          : Colors.white.withValues(alpha: 0.72),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.primary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.75)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: scheme.primary, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? const Color(0xff050a10) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      elevation: 24,
      backgroundColor: dark ? const Color(0xff030609) : const Color(0xfff8fbff),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 16,
      backgroundColor: dark ? const Color(0xff071522) : const Color(0xff163a58),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: scheme.surfaceContainerHighest,
      linearMinHeight: 5,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary.withValues(alpha: 0.52)
            : scheme.surfaceContainerHighest,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.secondary
            : scheme.onSurfaceVariant,
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

class NeoBackground extends StatefulWidget {
  const NeoBackground({super.key, required this.child});

  final Widget child;

  @override
  State<NeoBackground> createState() => _NeoBackgroundState();
}

class _NeoBackgroundState extends State<NeoBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _NeoBackgroundPainter(
            dark: Theme.of(context).brightness == Brightness.dark,
            progress: reduceMotion ? 0.35 : _controller.value,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _NeoBackgroundPainter extends CustomPainter {
  const _NeoBackgroundPainter({required this.dark, required this.progress});

  final bool dark;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const <Color>[
                  NeoColors.darkBackground,
                  NeoColors.darkBackgroundEnd,
                ]
              : const <Color>[
                  NeoColors.lightBackground,
                  NeoColors.lightBackgroundEnd,
                ],
        ).createShader(rect),
    );
    final shift = math.sin(progress * math.pi * 2);
    _orb(
      canvas,
      Offset(size.width * (0.78 + shift * 0.05), size.height * 0.08),
      size.shortestSide * 0.72,
      (dark ? NeoColors.blue : const Color(0xff65b9f2)).withValues(
        alpha: dark ? 0.055 : 0.2,
      ),
    );
    _orb(
      canvas,
      Offset(size.width * (0.12 - shift * 0.04), size.height * 0.68),
      size.shortestSide * 0.62,
      (dark ? NeoColors.violet : const Color(0xffa79bf5)).withValues(
        alpha: dark ? 0.03 : 0.13,
      ),
    );
  }

  void _orb(Canvas canvas, Offset center, double radius, Color color) {
    final bounds = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0)],
        ).createShader(bounds),
    );
  }

  @override
  bool shouldRepaint(_NeoBackgroundPainter oldDelegate) =>
      oldDelegate.dark != dark || oldDelegate.progress != progress;
}

class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 24,
    this.accent,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? accent;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final effectiveAccent = accent ?? theme.colorScheme.primary;
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? <Color>[
                  Color.lerp(NeoColors.darkPanelHigh, effectiveAccent, 0.032)!,
                  NeoColors.darkPanel.withValues(alpha: 0.985),
                ]
              : <Color>[
                  Colors.white.withValues(alpha: 0.96),
                  Color.lerp(NeoColors.lightPanel, effectiveAccent, 0.045)!,
                ],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Color.lerp(
            theme.colorScheme.outline,
            effectiveAccent,
            0.16,
          )!.withValues(alpha: dark ? 0.78 : 0.62),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.24 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return content;
    return NeoPressable(
      onTap: onTap!,
      semanticLabel: semanticLabel,
      child: content,
    );
  }
}

class NeoPressable extends StatefulWidget {
  const NeoPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.haptic = false,
    this.scale = 0.975,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onTap;
  final String? semanticLabel;
  final bool haptic;
  final double scale;
  final bool enabled;

  @override
  State<NeoPressable> createState() => _NeoPressableState();
}

class _NeoPressableState extends State<NeoPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.enabled,
    label: widget.semanticLabel,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: widget.enabled
          ? () => setState(() => _pressed = false)
          : null,
      onTapUp: widget.enabled ? (_) => setState(() => _pressed = false) : null,
      onTap: widget.enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    ),
  );
}

class NeoIconButton extends StatelessWidget {
  const NeoIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.accent,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    final enabled = onPressed != null;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.42,
        child: NeoPressable(
          onTap: onPressed ?? () {},
          semanticLabel: tooltip,
          haptic: enabled,
          enabled: enabled,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: enabled ? color : null, size: 22),
          ),
        ),
      ),
    );
  }
}

class NeoPill extends StatelessWidget {
  const NeoPill({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: effectiveColor),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: effectiveColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NeoRoute<T> extends PageRouteBuilder<T> {
  NeoRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final reduceMotion =
              MediaQuery.maybeOf(context)?.disableAnimations ?? false;
          if (reduceMotion) return child;
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.035, 0.045),
                end: Offset.zero,
              ).animate(curved),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
                child: child,
              ),
            ),
          );
        },
      );
}

class NeoScaffold extends StatelessWidget {
  const NeoScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) => NeoBackground(
    child: Scaffold(
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      body: body,
    ),
  );
}
