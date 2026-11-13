import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class C {
  static const Color bg = Color(0xFF081322);
  static const Color surface = Color(0xFF15283B);
  static const Color surface2 = Color(0xFF102235);
  static const Color gold = Color(0xFFF2C77E);
  static const Color mint = Color(0xFF91D9C7);
  static const Color violet = Color(0xFFB8B2FA);
  static const Color white = Color(0xFFF6F4F0);
  static const Color muted = Color(0xFFA4B0BD);
  static const Color line = Color(0xFF294254);
}

ThemeData appTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
    bodyColor: C.white, displayColor: C.white,
  );
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
      primary: C.gold,
      onPrimary: C.bg,
      secondary: C.mint,
      surface: C.surface,
      onSurface: C.white,
      error: Color(0xFFFFA9AA),
    ),
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: GoogleFonts.cairo(
        fontSize: 23, fontWeight: FontWeight.w700, color: C.white,
      ),
      iconTheme: const IconThemeData(color: C.white),
    ),
    dividerColor: C.line,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: C.surface,
      contentTextStyle: TextStyle(color: C.white),
    ),
  );
}

const _goldGradient = LinearGradient(
  colors: [Color(0xFFF6DEAE), Color(0xFFDCAC64)],
  begin: Alignment.topRight,
  end: Alignment.bottomLeft,
);

class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.text, required this.onPressed, this.icon = Icons.arrow_back_rounded});
  final String text;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.42 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: _goldGradient,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [BoxShadow(color: Color(0x30E8B970), blurRadius: 18, offset: Offset(0, 7))],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(text, style: const TextStyle(color: C.bg, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  Icon(icon, color: C.bg, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.borderColor, this.onTap});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: C.surface.withValues(alpha: 0.83),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: borderColor ?? C.line.withValues(alpha: .75)),
        boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 22, offset: Offset(0, 14))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AuroraScaffold extends StatelessWidget {
  const AuroraScaffold({super.key, required this.child, this.bottomNavigationBar});
  final Widget child;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: C.bg)),
          Positioned(
            left: -150, top: -160, width: 440, height: 440,
            child: IgnorePointer(child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(
                colors: [C.violet.withValues(alpha: .16), Colors.transparent],
              )),
            )),
          ),
          Positioned(
            right: -170, top: 220, width: 420, height: 420,
            child: IgnorePointer(child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(
                colors: [C.gold.withValues(alpha: .105), Colors.transparent],
              )),
            )),
          ),
          SafeArea(bottom: false, child: child),
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.suffix});
  final String title;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(height: 18, width: 3, decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      const Spacer(),
      if (suffix != null) suffix!,
    ],
  );
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 68, this.color = C.gold, this.stroke = 6});
  final double value;
  final double size;
  final Color color;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size, width: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 560),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(child: CircularProgressIndicator(
              value: animatedValue, color: color, backgroundColor: C.white.withValues(alpha: .09),
              strokeCap: StrokeCap.round, strokeWidth: stroke,
            )),
            Text('${(animatedValue * 100).round()}٪', style: TextStyle(color: color, fontSize: size / 4.5, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

String clockString(int totalMinutes) {
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  final displayHour = h % 12 == 0 ? 12 : h % 12;
  return '$displayHour:${m.toString().padLeft(2, '0')} ${h < 12 ? 'ص' : 'م'}';
}
