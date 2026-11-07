import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_icons.dart';

class NavItemData {
  const NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge = 0,
    this.primary = false,
    this.avatar,
  });
  final String label;
  final IconData icon, activeIcon;
  final int badge;

  // The primary item is the round button in the bulge, on the same row as the others.
  final bool primary;

  // Replaces the icon, for the account button that shows the profile photo.
  final Widget Function(bool selected)? avatar;
}

const _barHeight = 64.0;
const _bump = 14.0;

// A floating bar with a bulge around the primary button. A dot slides under the active tab.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onTap,
    this.onLogout,
  });
  final List<NavItemData> items;
  final int selected;
  final ValueChanged<int> onTap;

  // When set, a red log out button slides in beside the bar.
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final primaryIndex = items.indexWhere((item) => item.primary);
    final bump = primaryIndex >= 0 ? _bump : 0.0;
    final surface = dark ? const Color(0xFF1B1F1D) : Colors.white;
    final edge = dark ? const Color(0xFF2B322E) : const Color(0xFFE6E9E6);
    final active = dark ? Colors.white : const Color(0xFF0E1A14);
    final quiet = dark ? const Color(0xFF8C958F) : const Color(0xFF8A918C);
    final green = dark ? const Color(0xFF3DBE78) : const Color(0xFF1E8E4E);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: SizedBox(
          height: _barHeight + bump,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final slot = box.maxWidth / items.length;
                    final hasSelection =
                        selected >= 0 && selected < items.length;
                    final centerX = primaryIndex >= 0
                        ? slot * primaryIndex + slot / 2
                        : 0.0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _BarPainter(
                              color: surface,
                              edge: edge,
                              shadow: Colors.black.withValues(
                                alpha: dark ? .55 : .14,
                              ),
                              notchX: primaryIndex >= 0 ? centerX : null,
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutBack,
                          left:
                              (hasSelection ? selected : 0) * slot +
                              slot / 2 -
                              3,
                          bottom: 9,
                          width: 6,
                          height: 6,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: hasSelection ? 1 : 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: green,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var i = 0; i < items.length; i++)
                              Expanded(
                                child: _NavButton(
                                  data: items[i],
                                  selected: i == selected,
                                  activeColor: active,
                                  quietColor: quiet,
                                  accent: green,
                                  barSurface: surface,
                                  bump: bump,
                                  onTap: () => onTap(i),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      alignment: Alignment.centerRight,
                      child: child,
                    ),
                  ),
                  child: onLogout == null
                      ? const SizedBox(key: ValueKey('no-logout'))
                      : Padding(
                          key: const ValueKey('logout'),
                          padding: const EdgeInsets.only(left: 10),
                          child: _LogoutButton(onTap: onLogout!),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.color,
    required this.edge,
    required this.shadow,
    required this.notchX,
  });
  final Color color, edge, shadow;
  final double? notchX;

  @override
  void paint(Canvas canvas, Size size) {
    final top = notchX == null ? 0.0 : _bump;
    final pill = Path()
      ..addRRect(
        RRect.fromLTRBR(
          0,
          top,
          size.width,
          size.height,
          const Radius.circular(_barHeight / 2),
        ),
      );
    var shape = pill;
    if (notchX != null) {
      const half = 48.0;
      final cx = notchX!;
      final hill = Path()
        ..moveTo(cx - half, top + 2)
        ..cubicTo(cx - half * .45, top, cx - half * .55, 0, cx, 0)
        ..cubicTo(cx + half * .55, 0, cx + half * .45, top, cx + half, top + 2)
        ..close();
      shape = Path.combine(PathOperation.union, pill, hill);
    }
    canvas.drawShadow(shape, shadow, 16, true);
    canvas.drawPath(shape, Paint()..color = color);
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = edge,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.color != color || old.notchX != notchX || old.edge != edge;
}

class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.data,
    required this.selected,
    required this.activeColor,
    required this.quietColor,
    required this.accent,
    required this.barSurface,
    required this.bump,
    required this.onTap,
  });
  final NavItemData data;
  final bool selected;
  final Color activeColor, quietColor, accent, barSurface;
  final double bump;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final Widget content;
    if (data.primary) {
      content = SizedBox(
        width: 72,
        height: 72,
        child: CustomPaint(
          painter: _HaloPainter(widget.accent),
          child: Center(
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(widget.accent, Colors.white, .18)!,
                    widget.accent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: .45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(data.icon, color: Colors.white, size: 26),
            ),
          ),
        ),
      );
    } else {
      final color = widget.selected ? widget.activeColor : widget.quietColor;
      Widget icon;
      if (data.avatar != null) {
        icon = Container(
          key: ValueKey('avatar-${widget.selected}'),
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.selected ? widget.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: data.avatar!(widget.selected),
        );
      } else {
        icon = Icon(
          widget.selected ? data.activeIcon : data.icon,
          key: ValueKey(widget.selected),
          color: color,
          size: 25,
        );
      }
      content = Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedScale(
              scale: widget.selected ? 1.12 : 1,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutBack,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: Tween(begin: .7, end: 1.0).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: icon,
              ),
            ),
            if (data.badge > 0)
              Positioned(
                right: -7,
                top: -5,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5483F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.barSurface, width: 1.5),
                  ),
                  child: Text(
                    data.badge > 9 ? '9+' : '${data.badge}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Semantics(
      button: true,
      selected: widget.selected,
      label: data.label,
      excludeSemantics: true,
      child: Tooltip(
        message: data.label,
        triggerMode: TooltipTriggerMode.manual,
        excludeFromSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          child: AnimatedScale(
            scale: _down ? .86 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: data.primary
                  ? content
                  : SizedBox(
                      height: _barHeight,
                      child: Center(child: content),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// A ring of small dots around the primary button.
class _HaloPainter extends CustomPainter {
  _HaloPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final paint = Paint()..color = color.withValues(alpha: .5);
    const count = 28;
    final radius = size.width / 2 - 2;
    for (var i = 0; i < count; i++) {
      final angle = i * 2 * math.pi / count;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        1.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HaloPainter old) => old.color != color;
}

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFD7403A);
    return Semantics(
      button: true,
      label: 'Log out',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Log out',
        triggerMode: TooltipTriggerMode.manual,
        excludeFromSemantics: true,
        child: GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _down = true),
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          child: AnimatedScale(
            scale: _down ? .9 : 1,
            duration: const Duration(milliseconds: 110),
            child: Container(
              width: _barHeight,
              height: _barHeight,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEA5A52), red],
                ),
                boxShadow: [
                  BoxShadow(
                    color: red.withValues(alpha: .4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Ph.signOutBold, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
