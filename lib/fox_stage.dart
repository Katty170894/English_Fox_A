import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'fox_look.dart';
import 'game_state.dart';
import 'sound.dart';

/// How the fox reacts.
enum FoxMood {
  /// Just bought something: big double hop, sparkles, hearts, speech bubble.
  joy,

  /// Tried something on / was tapped: one small hop.
  hop,

  /// Not enough coins yet: a gentle "no-no" head shake.
  nope
}

/// The big fox in the shop. Call [HappyFoxStageState.celebrate] (through a
/// GlobalKey) to make it react. Tapping the fox makes it hop and go "boing".
class HappyFoxStage extends StatefulWidget {
  final String character;
  final FoxLook look;
  final double size;
  final bool animateItems;
  const HappyFoxStage(
      {super.key,
      required this.character,
      required this.look,
      this.size = 200,
      this.animateItems = false});

  @override
  State<HappyFoxStage> createState() => HappyFoxStageState();
}

class HappyFoxStageState extends State<HappyFoxStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1900));
  FoxMood _mood = FoxMood.joy;
  String _phrase = '';
  int _count = 0;

  static const _joyPhrases = [
    'Wow, I love it!',
    'So cool!',
    'Yippee!',
    'Thank you!',
    'Look at me!'
  ];
  static const _hopPhrases = ['Hee-hee!', 'Boing!', 'Hello!', 'Yay!'];
  static const _nopePhrases = ['I need more coins!', 'Keep learning!'];

  void celebrate(FoxMood mood) {
    if (!mounted) return;
    _count++;
    final phrases = mood == FoxMood.joy
        ? _joyPhrases
        : mood == FoxMood.hop
            ? _hopPhrases
            : _nopePhrases;
    setState(() {
      _mood = mood;
      _phrase = phrases[_count % phrases.length];
    });
    _c.duration = Duration(
        milliseconds: mood == FoxMood.joy
            ? 1900
            : mood == FoxMood.hop
                ? 900
                : 800);
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double _bump(double t, double center, double width) =>
      math.max(0.0, 1 - (t - center).abs() / width);

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final h = s + 70;
    return Center(
        child: LayoutBuilder(builder: (context, box) {
      final w = math.min(box.maxWidth.isFinite ? box.maxWidth : s + 150, s + 150);
      return SizedBox(
          width: w,
          height: h,
          child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final t = _c.value;
                double dy = 0, dx = 0, sy = 1, sx = 1, rot = 0;
                switch (_mood) {
                  case FoxMood.joy:
                    if (t < .38) {
                      dy = -math.sin(math.pi * t / .38) * .16 * s;
                    } else if (t < .62) {
                      dy = -math.sin(math.pi * (t - .38) / .24) * .08 * s;
                    }
                    final landJoy = _bump(t, .38, .05) + _bump(t, .62, .04);
                    sy = 1 - .09 * landJoy;
                    sx = 1 + .07 * landJoy;
                    rot = .09 * math.sin(t * math.pi * 6) * (1 - t);
                    break;
                  case FoxMood.hop:
                    dy = -math.sin(math.pi * t) * .11 * s;
                    final landHop = _bump(t, 1.0, .08);
                    sy = 1 - .07 * landHop;
                    sx = 1 + .05 * landHop;
                    rot = .06 * math.sin(t * math.pi * 3) * (1 - t);
                    break;
                  case FoxMood.nope:
                    dx = math.sin(t * math.pi * 7) * .035 * s * (1 - t);
                    rot = math.sin(t * math.pi * 7) * .035 * (1 - t);
                    break;
                }
                // the speech bubble fades in quickly, stays, fades out
                final bubble = (_phrase.isEmpty || t <= 0 || t >= 1)
                    ? 0.0
                    : math.min(math.min(t / .08, 1.0), (1 - t) / .15)
                        .clamp(0.0, 1.0)
                        .toDouble();
                final head = Offset(w / 2, h - 6 - s * .55);

                final fox = GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      SoundService.instance.playBoing();
                      celebrate(FoxMood.hop);
                    },
                    child: Semantics(
                        button: true,
                        label: 'Tap the fox',
                        child: SizedBox(
                            width: s,
                            height: s,
                            child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                      left: -s * .14,
                                      top: -s * .14,
                                      right: -s * .14,
                                      bottom: -s * .14,
                                      child: IgnorePointer(
                                          child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: RadialGradient(
                                                      colors: [
                                                    const Color(0x77FFE9A8),
                                                    const Color(0xFFFFE9A8)
                                                        .withValues(alpha: 0)
                                                  ])))) ),
                                  FoxAvatar(
                                      character: widget.character,
                                      size: s,
                                      look: widget.look,
                                      animateItems: widget.animateItems),
                                ]))));

                return Stack(clipBehavior: Clip.none, children: [
                  Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Transform.translate(
                              offset: Offset(dx, dy),
                              child: Transform(
                                  alignment: Alignment.bottomCenter,
                                  transform:
                                      Matrix4.diagonal3Values(sx, sy, 1),
                                  child: Transform.rotate(
                                      angle: rot,
                                      alignment: Alignment.bottomCenter,
                                      child: fox))))),
                  if (_mood != FoxMood.nope && t > 0 && t < 1)
                    Positioned.fill(
                        child: IgnorePointer(
                            child: CustomPaint(
                                painter: _SparklePainter(
                                    t, _mood == FoxMood.joy, head, s)))),
                  if (bubble > 0)
                    Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                            child: Align(
                                alignment: Alignment.topRight,
                                child: Opacity(
                                    opacity: bubble,
                                    child: Transform.scale(
                                        scale: .85 + .15 * bubble,
                                        alignment: Alignment.bottomLeft,
                                        child: _Bubble(_phrase)))))),
                ]);
              }));
    }));
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  const _Bubble(this.text);
  @override
  Widget build(BuildContext context) => Container(
      constraints: const BoxConstraints(maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF77CEF9), width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))
          ]),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF123C62))));
}

/// Sparkles bursting out of the fox's head and hearts floating up.
class _SparklePainter extends CustomPainter {
  final double t;
  final bool big;
  final Offset head;
  final double s;
  const _SparklePainter(this.t, this.big, this.head, this.s);

  static const _palette = [
    Color(0xFFFFC744),
    Color(0xFFFF7FB5),
    Color(0xFF5CC8FF),
    Color(0xFF7BE07B),
    Color(0xFFFF9F43),
  ];

  Path _sparkle(Offset c, double r, double rot) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final rad = i.isEven ? r : r * .32;
      final a = rot + i * math.pi / 4;
      final p = Offset(c.dx + math.cos(a) * rad, c.dy + math.sin(a) * rad);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = big ? 14 : 6;
    final e = Curves.easeOut.transform(math.min(1.0, t / .8));
    final fade = (1 - t / .95).clamp(0.0, 1.0).toDouble();
    for (var i = 0; i < n; i++) {
      final angle = i * 2 * math.pi / n + .35 * math.sin(i * 7.1);
      final speed = s * (.42 + .28 * ((i * 37 % 10) / 10));
      final dist = s * .2 + speed * e;
      final pos = head +
          Offset(math.cos(angle) * dist, math.sin(angle) * dist - e * s * .08);
      final r = s * .05 * (1 + (i % 3) * .35) * (big ? 1 : .8);
      canvas.drawPath(_sparkle(pos, r, t * 3 + i),
          Paint()..color = _palette[i % _palette.length].withValues(alpha: fade));
    }
    if (big) {
      for (var j = 0; j < 4; j++) {
        final u = ((t - j * .08) / .7).clamp(0.0, 1.0).toDouble();
        if (u <= 0 || u >= 1) continue;
        final x = head.dx + (j - 1.5) * s * .17 + math.sin(u * 6 + j) * s * .03;
        final y = head.dy - s * .18 - u * s * .55;
        canvas.drawPath(heartPath(x, y, s * (.055 + j % 2 * .015)),
            Paint()..color = const Color(0xFFFF5C8A).withValues(alpha: math.sin(math.pi * u)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter old) =>
      old.t != t || old.big != big || old.head != head || old.s != s;
}
