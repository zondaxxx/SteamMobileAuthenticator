import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Calm, Steam-inspired visual language: deep charcoal-blue surfaces,
/// one restrained accent family, hairline borders and almost no glow.
abstract final class NeoColors {
  // Dark palette.
  static const darkBackground = Color(0xff0c0f14);
  static const darkBackgroundEnd = Color(0xff10141b);
  static const darkPanel = Color(0xff151b24);
  static const darkPanelHigh = Color(0xff1c2431);
  static const darkBorder = Color(0xff27303d);

  // Accents.
  static const blue = Color(0xff58a6e8);
  static const cyan = Color(0xff41c8ad);
  static const violet = Color(0xff9089e8);
  static const mint = Color(0xff4ecf96);
  static const amber = Color(0xffe5b566);
  static const danger = Color(0xffe26370);

  // Light palette.
  static const lightBackground = Color(0xfff2f5f9);
  static const lightBackgroundEnd = Color(0xffeaeff6);
  static const lightPanel = Color(0xffffffff);
  static const lightPanelHigh = Color(0xffffffff);
  static const lightBorder = Color(0xffd9e0ea);

  /// Deterministic accent for generated placeholders (avatars, chips).
  static Color forSeed(String seed) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return const <Color>[blue, cyan, violet, mint, amber][hash % 5];
  }
}

ThemeData steamNeoTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? NeoColors.blue : const Color(0xff2b6cb0),
    onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xff1d3348) : const Color(0xffd8eaf9),
    onPrimaryContainer: dark
        ? const Color(0xffcfe6fa)
        : const Color(0xff12395c),
    secondary: dark ? NeoColors.cyan : const Color(0xff17735f),
    onSecondary: Colors.white,
    secondaryContainer: dark
        ? const Color(0xff17352e)
        : const Color(0xffd3efe5),
    onSecondaryContainer: dark
        ? const Color(0xffc8ecdf)
        : const Color(0xff0c3d30),
    tertiary: dark ? NeoColors.violet : const Color(0xff5c53b8),
    onTertiary: Colors.white,
    tertiaryContainer: dark ? const Color(0xff2c2949) : const Color(0xffe5e2f8),
    onTertiaryContainer: dark
        ? const Color(0xffded9f8)
        : const Color(0xff241f57),
    error: dark ? NeoColors.danger : const Color(0xffb3261e),
    onError: Colors.white,
    errorContainer: dark ? const Color(0xff3f2026) : const Color(0xffffdad6),
    onErrorContainer: dark ? const Color(0xffffdad6) : const Color(0xff410e0b),
    surface: dark ? NeoColors.darkPanel : NeoColors.lightPanel,
    onSurface: dark ? const Color(0xffe6ebf2) : const Color(0xff182130),
    surfaceContainerHighest: dark
        ? NeoColors.darkPanelHigh
        : const Color(0xffe6ebf2),
    onSurfaceVariant: dark ? const Color(0xff93a0b4) : const Color(0xff56637a),
    outline: dark ? NeoColors.darkBorder : NeoColors.lightBorder,
    outlineVariant: dark ? const Color(0xff1f2733) : const Color(0xffe3e9f1),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? const Color(0xffe6ebf2) : const Color(0xff2a3442),
    onInverseSurface: dark ? const Color(0xff1a212c) : Colors.white,
    inversePrimary: dark ? const Color(0xff2b6cb0) : const Color(0xff9ccbf2),
  );
  final baseText = ThemeData(brightness: brightness).textTheme
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  final textTheme = baseText.copyWith(
    displaySmall: baseText.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
    ),
    headlineLarge: baseText.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
    ),
    headlineMedium: baseText.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
    ),
    headlineSmall: baseText.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
    ),
    titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: baseText.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
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
      color: scheme.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.55)),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark
          ? NeoColors.darkBackground.withValues(alpha: 0.65)
          : Colors.white.withValues(alpha: 0.85),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: textTheme.labelLarge,
        foregroundColor: scheme.onSurface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? NeoColors.darkPanelHigh : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    dialogTheme: DialogThemeData(
      elevation: 16,
      backgroundColor: dark ? NeoColors.darkPanel : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      backgroundColor: dark ? NeoColors.darkPanelHigh : const Color(0xff233247),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: scheme.surfaceContainerHighest,
      linearMinHeight: 4,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest,
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? scheme.onPrimary
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

/// Static, battery-friendly backdrop: a soft vertical gradient and faint
/// corner washes. No animation loop.
class NeoBackground extends StatelessWidget {
  const NeoBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dark
              ? const <Color>[
                  NeoColors.darkBackground,
                  NeoColors.darkBackgroundEnd,
                ]
              : const <Color>[
                  NeoColors.lightBackground,
                  NeoColors.lightBackgroundEnd,
                ],
        ),
      ),
      child: CustomPaint(
        painter: _NeoWashPainter(dark: dark),
        child: child,
      ),
    );
  }
}

class _NeoWashPainter extends CustomPainter {
  const _NeoWashPainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    void wash(Color color, Offset center, double radius) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[color, color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: center, radius: radius)),
      );
    }

    wash(
      (dark ? NeoColors.blue : const Color(0xff9dc8ee)).withValues(
        alpha: dark ? 0.05 : 0.28,
      ),
      Offset(size.width * 0.92, -size.height * 0.04),
      size.shortestSide * 0.7,
    );
    wash(
      (dark ? NeoColors.cyan : const Color(0xffb5e6d5)).withValues(
        alpha: dark ? 0.03 : 0.22,
      ),
      Offset(size.width * 0.05, size.height * 0.96),
      size.shortestSide * 0.55,
    );
  }

  @override
  bool shouldRepaint(_NeoWashPainter oldDelegate) => oldDelegate.dark != dark;
}

/// Solid panel with a hairline border. No gradients, no heavy shadows.
class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 18,
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
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Color.lerp(
            theme.colorScheme.outline,
            effectiveAccent,
            0.22,
          )!.withValues(alpha: dark ? 0.85 : 0.65),
        ),
        boxShadow: dark
            ? null
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
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

/// Rounded profile avatar with fade-in loading and letter fallback.
class NeoAvatar extends StatelessWidget {
  const NeoAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.accent,
    required this.radius,
    this.url,
  });

  final String name;
  final String? url;
  final double size;
  final double radius;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _Fallback(name: name, accent: accent),
            if (hasUrl)
              Image.network(
                url!,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: child,
                  );
                },
                errorBuilder: (_, _, _) =>
                    _Fallback(name: name, accent: accent),
              ),
          ],
        ),
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final letter = name.characters.firstOrNull?.toUpperCase() ?? '?';
    return ColoredBox(
      color: accent.withValues(alpha: 0.16),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
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
    this.scale = 0.98,
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
        duration: const Duration(milliseconds: 120),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: enabled ? color : null, size: 21),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 13, color: effectiveColor),
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
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
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
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curved),
              child: child,
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
