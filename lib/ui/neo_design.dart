import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Quiet, monochrome-first visual language. One accent, semantic colors only
/// for statuses, flat surfaces, generous whitespace.
abstract final class NeoColors {
  // Neutral surfaces.
  static const darkBackground = Color(0xff0e0f11);
  static const darkBackgroundEnd = Color(0xff0e0f11);
  static const darkPanel = Color(0xff161719);
  static const darkPanelHigh = Color(0xff1f2124);
  static const darkBorder = Color(0xff282a2e);

  // Single accent plus semantic statuses.
  static const blue = Color(0xff4c8df8);
  static const cyan = Color(0xff3aa981);
  static const violet = Color(0xff7d78d9);
  static const mint = Color(0xff35b374);
  static const amber = Color(0xffd9a02b);
  static const danger = Color(0xffe5484d);

  // Light neutrals.
  static const lightBackground = Color(0xfffafafa);
  static const lightBackgroundEnd = Color(0xfff4f4f6);
  static const lightPanel = Color(0xffffffff);
  static const lightPanelHigh = Color(0xffffffff);
  static const lightBorder = Color(0xffe7e7ea);

  /// Deterministic muted accent for generated placeholders.
  static Color forSeed(String seed) {
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return const <Color>[blue, cyan, violet, mint][hash % 4];
  }
}

ThemeData steamNeoTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: dark ? NeoColors.blue : const Color(0xff2f6fe4),
    onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xff1b2740) : const Color(0xffdde8fc),
    onPrimaryContainer: dark
        ? const Color(0xffcdddf9)
        : const Color(0xff143a7d),
    secondary: dark ? NeoColors.blue : const Color(0xff2f6fe4),
    onSecondary: Colors.white,
    secondaryContainer: dark
        ? const Color(0xff1b2740)
        : const Color(0xffdde8fc),
    onSecondaryContainer: dark
        ? const Color(0xffcdddf9)
        : const Color(0xff143a7d),
    tertiary: dark ? const Color(0xff7d78d9) : const Color(0xff5550c0),
    onTertiary: Colors.white,
    tertiaryContainer: dark ? const Color(0xff26243d) : const Color(0xffe6e4fa),
    onTertiaryContainer: dark
        ? const Color(0xffdedbf8)
        : const Color(0xff201c56),
    error: dark ? NeoColors.danger : const Color(0xffcc3a3f),
    onError: Colors.white,
    errorContainer: dark ? const Color(0xff3a2023) : const Color(0xffffdad9),
    onErrorContainer: dark ? const Color(0xffffdad9) : const Color(0xff41090c),
    surface: dark ? NeoColors.darkPanel : NeoColors.lightPanel,
    onSurface: dark ? const Color(0xffececee) : const Color(0xff191a1c),
    surfaceContainerHighest: dark
        ? NeoColors.darkPanelHigh
        : const Color(0xffefeff1),
    onSurfaceVariant: dark ? const Color(0xff9a9ca2) : const Color(0xff63666c),
    outline: dark ? NeoColors.darkBorder : NeoColors.lightBorder,
    outlineVariant: dark ? const Color(0xff202225) : const Color(0xffeeeef0),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: dark ? const Color(0xffececee) : const Color(0xff232527),
    onInverseSurface: dark ? const Color(0xff191a1c) : Colors.white,
    inversePrimary: dark ? const Color(0xff2f6fe4) : const Color(0xffa8c6fb),
  );
  final baseText = ThemeData(brightness: brightness).textTheme
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  final textTheme = baseText.copyWith(
    displaySmall: baseText.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -1,
    ),
    headlineLarge: baseText.headlineLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.8,
    ),
    headlineMedium: baseText.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
    headlineSmall: baseText.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    titleMedium: baseText.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
    ),
    labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w500),
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
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: scheme.outline.withValues(alpha: dark ? 0.7 : 1),
        ),
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
          ? NeoColors.darkBackground.withValues(alpha: 0.6)
          : Colors.white.withValues(alpha: 0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant),
      prefixIconColor: scheme.onSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.primary, width: 1.3),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 46),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: textTheme.labelLarge,
        foregroundColor: scheme.onSurface,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size.square(42),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? NeoColors.darkPanelHigh : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      elevation: 8,
      backgroundColor: dark ? NeoColors.darkPanel : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      backgroundColor: dark ? NeoColors.darkPanelHigh : const Color(0xff222428),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
      circularTrackColor: scheme.surfaceContainerHighest,
      linearMinHeight: 3,
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

/// Solid backdrop only — no decoration, no animation.
class NeoBackground extends StatelessWidget {
  const NeoBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? NeoColors.darkBackground : NeoColors.lightBackground,
      child: child,
    );
  }
}

/// Flat card: quiet fill, hairline outline, no shadows or gradients.
class NeoSurface extends StatelessWidget {
  const NeoSurface({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
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
    final content = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: theme.colorScheme.outline),
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

/// Small status dot used instead of loud badges.
class NeoDot extends StatelessWidget {
  const NeoDot({super.key, required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Rounded profile avatar with fade-in loading and letter fallback.
class NeoAvatar extends StatelessWidget {
  const NeoAvatar({
    super.key,
    required this.name,
    required this.size,
    required this.radius,
    this.url,
    this.accent,
  });

  final String name;
  final String? url;
  final double size;
  final double radius;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent =
        accent ?? NeoColors.forSeed(name.isEmpty ? '?' : name);
    final hasUrl = url != null && url!.startsWith('http');
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _Fallback(name: name, accent: effectiveAccent),
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
                    _Fallback(name: name, accent: effectiveAccent),
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
      color: accent.withValues(alpha: 0.14),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
    this.scale = 0.985,
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
        duration: const Duration(milliseconds: 110),
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
    final enabled = onPressed != null;
    final effectiveAccent =
        accent ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: enabled ? 1 : 0.38,
        child: NeoPressable(
          onTap: onPressed ?? () {},
          semanticLabel: tooltip,
          haptic: enabled,
          enabled: enabled,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Icon(icon, color: effectiveAccent, size: 20),
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
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
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
                fontWeight: FontWeight.w600,
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
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
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
          return FadeTransition(opacity: curved, child: child);
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
