import 'package:flutter/material.dart';

class NavItemData {
  const NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badge = 0,
    this.primary = false,
    this.destructive = false,
    this.avatar,
  });
  final String label;
  final IconData icon, activeIcon;
  final int badge;

  // The primary item is the round button in the bulge, on the same row as the others.
  final bool primary;

  // Drawn in red, for actions like logging out.
  final bool destructive;

  // Replaces the icon, for the account button that shows the profile photo.
  final Widget Function(bool selected)? avatar;
}

const _barHeight = 64.0;
const _bump = 14.0;
const _red = Color(0xFFD7403A);

// A floating bar with a bulge around the primary button. Every item has a name under its icon,
// and a slim indicator slides along the top edge to the active tab.
class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.items,
    required this.selected,
    required this.onTap,
  });
  final List<NavItemData> items;
  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final primaryIndex = items.indexWhere((item) => item.primary);
    final bump = primaryIndex >= 0 ? _bump : 0.0;
    final surface = dark ? const Color(0xFF1B1F1D) : Colors.white;
    final edge = dark ? const Color(0xFF2B322E) : const Color(0xFFE6E9E6);
    final active = dark ? Colors.white : const Color(0xFF0E1A14);
    final quiet = dark ? const Color(0xFF8C958F) : const Color(0xFF7D857F);
    final green = dark ? const Color(0xFF3DBE78) : const Color(0xFF1E8E4E);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: SizedBox(
          height: _barHeight + bump,
          child: LayoutBuilder(
            builder: (context, box) {
              final slot = box.maxWidth / items.length;
              final hasSelection = selected >= 0 && selected < items.length;
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
                    left: (hasSelection ? selected : 0) * slot + slot / 2 - 10,
                    top: bump + 5,
                    width: 20,
                    height: 3.5,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: hasSelection ? 1 : 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: green,
                          borderRadius: BorderRadius.circular(2),
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
      const half = 50.0;
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
    required this.onTap,
  });
  final NavItemData data;
  final bool selected;
  final Color activeColor, quietColor, accent, barSurface;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final color = data.destructive
        ? _red
        : widget.selected
        ? widget.activeColor
        : widget.quietColor;

    final Widget icon;
    if (data.primary) {
      icon = Container(
        width: 48,
        height: 48,
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
              color: widget.accent.withValues(alpha: .4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(data.icon, color: Colors.white, size: 24),
      );
    } else if (data.avatar != null) {
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
        size: 24,
      );
    }

    final badge = data.badge > 0
        ? Positioned(
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
          )
        : null;

    final content = Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedScale(
                scale: widget.selected && !data.primary ? 1.1 : 1,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutBack,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: Tween(begin: .7, end: 1.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                  child: icon,
                ),
              ),
              ?badge,
            ],
          ),
          const SizedBox(height: 3),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: data.primary ? widget.accent : color,
              fontSize: 11,
              height: 1.1,
              fontWeight: widget.selected || data.primary
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );

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
            scale: _down ? .88 : 1,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            child: SizedBox.expand(
              child: Align(alignment: Alignment.bottomCenter, child: content),
            ),
          ),
        ),
      ),
    );
  }
}
