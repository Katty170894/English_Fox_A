import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_state.dart';
import 'pictures.dart';

// ---------------------------------------------------------------------------
// Where things go on each animal picture.
//
// Every number is a fraction (0..1) of the picture, measured on the 313 px
// tiles of assets/animals-atlas.png. If an accessory ever looks a bit off on
// one animal, nudge that animal's numbers here - nothing else needs to change.
// ---------------------------------------------------------------------------
class _Anchor {
  final Offset eyeL, eyeR; // centre of each eye
  final Offset hat; // middle of the hat's brim, on top of the head
  final double hatW; // width of a hat
  final Offset neck; // middle of the scarf
  final double scarfW; // width of the scarf
  const _Anchor(
      {required this.eyeL,
      required this.eyeR,
      required this.hat,
      required this.hatW,
      required this.neck,
      required this.scarfW});

  /// How much the head is tilted (radians); accessories follow it.
  double get tilt =>
      math.atan2(eyeR.dy - eyeL.dy, eyeR.dx - eyeL.dx);
}

const _anchors = <String, _Anchor>{
  'fox': _Anchor(
      eyeL: Offset(.468, .441),
      eyeR: Offset(.669, .399),
      hat: Offset(.545, .245),
      hatW: .34,
      neck: Offset(.600, .645),
      scarfW: .44),
  'rabbit': _Anchor(
      eyeL: Offset(.378, .457),
      eyeR: Offset(.574, .470),
      hat: Offset(.470, .335),
      hatW: .28,
      neck: Offset(.470, .680),
      scarfW: .40),
  'bear': _Anchor(
      eyeL: Offset(.434, .345),
      eyeR: Offset(.638, .354),
      hat: Offset(.530, .185),
      hatW: .30,
      neck: Offset(.530, .630),
      scarfW: .46),
  'cat': _Anchor(
      eyeL: Offset(.371, .411),
      eyeR: Offset(.562, .450),
      hat: Offset(.445, .245),
      hatW: .28,
      neck: Offset(.455, .610),
      scarfW: .38),
};

// ---------------------------------------------------------------------------
// Shared little shapes
// ---------------------------------------------------------------------------

/// A 5-point star centred on ([cx], [cy]).
Path starPath(double cx, double cy, double r, [double inner = .48]) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final rad = i.isEven ? r : r * inner;
    final a = -math.pi / 2 + i * math.pi / 5;
    final x = cx + math.cos(a) * rad, y = cy + math.sin(a) * rad;
    if (i == 0) {
      path.moveTo(x, y);
    } else {
      path.lineTo(x, y);
    }
  }
  path.close();
  return path;
}

/// A heart centred on ([cx], [cy]), about 2*[r] wide.
Path heartPath(double cx, double cy, double r) {
  final path = Path()
    ..moveTo(cx, cy + r * .95)
    ..cubicTo(cx - r * 1.55, cy + r * .05, cx - r * .95, cy - r * 1.15, cx,
        cy - r * .38)
    ..cubicTo(cx + r * .95, cy - r * 1.15, cx + r * 1.55, cy + r * .05, cx,
        cy + r * .95)
    ..close();
  return path;
}

// ---------------------------------------------------------------------------
// The magic hat - drawn properly instead of a wizard emoji.
// Drawn on a 100 x 110 canvas; the middle of the brim is at (50, 92).
// ---------------------------------------------------------------------------
class MagicHatPainter extends CustomPainter {
  const MagicHatPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 110);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF2E1A66);

    // wide brim
    final brim = Rect.fromCenter(
        center: const Offset(50, 92), width: 98, height: 22);
    canvas.drawOval(
        brim,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8658E0), Color(0xFF4A2A9C)])
              .createShader(brim));
    canvas.drawOval(brim, line);

    // cone with a floppy, bent tip
    final cone = Path()
      ..moveTo(23, 92)
      ..cubicTo(27, 64, 38, 40, 56, 18)
      ..cubicTo(62, 10, 74, 6, 84, 14)
      ..cubicTo(75, 15, 69, 22, 67, 32)
      ..cubicTo(71, 52, 75, 72, 79, 92)
      ..quadraticBezierTo(51, 101, 23, 92)
      ..close();
    canvas.drawPath(
        cone,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFA070F5), Color(0xFF5B33BF)])
              .createShader(cone.getBounds()));

    canvas.save();
    canvas.clipPath(cone);
    // golden band around the base
    final band = Path()
      ..moveTo(15, 77)
      ..quadraticBezierTo(51, 87, 87, 77)
      ..lineTo(87, 104)
      ..quadraticBezierTo(51, 114, 15, 104)
      ..close();
    canvas.drawPath(
        band,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFDD6B), Color(0xFFF0A21A)])
              .createShader(band.getBounds()));
    canvas.drawPath(
        Path()
          ..moveTo(15, 77)
          ..quadraticBezierTo(51, 87, 87, 77),
        line..strokeWidth = 1.6);
    // soft sheen on the left side
    canvas.drawPath(
        Path()
          ..moveTo(31, 84)
          ..cubicTo(34, 66, 42, 48, 55, 30),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = Colors.white.withValues(alpha: .24));
    // little stars and sparkles
    final gold = Paint()..color = const Color(0xFFFFE066);
    canvas.drawPath(starPath(46, 65, 6.5), gold);
    canvas.drawPath(starPath(59, 51, 5), gold);
    canvas.drawPath(starPath(52, 37, 3.6), gold);
    final dot = Paint()..color = Colors.white.withValues(alpha: .8);
    canvas.drawCircle(const Offset(38, 54), 1.4, dot);
    canvas.drawCircle(const Offset(64, 68), 1.6, dot);
    canvas.drawCircle(const Offset(54, 58), 1.1, dot);
    canvas.restore();

    line.strokeWidth = 2.8;
    canvas.drawPath(cone, line);

    // buckle on the band
    final buckle = RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(51, 91), width: 13, height: 11),
        const Radius.circular(3));
    canvas.drawRRect(buckle, Paint()..color = const Color(0xFFFFF0A8));
    canvas.drawRRect(buckle, line..strokeWidth = 1.8);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: const Offset(51, 91), width: 6, height: 5),
            const Radius.circular(1.5)),
        Paint()..color = const Color(0xFF7B4FD8));
    // golden bobble on the tip
    canvas.drawCircle(const Offset(84, 14), 4.2, Paint()..color = const Color(0xFFFFD34D));
    canvas.drawCircle(const Offset(84, 14), 4.2, line..strokeWidth = 1.8);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MagicHatPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Glasses: drawn straight over the eyes, so they follow the head's tilt.
// ---------------------------------------------------------------------------
class GlassesPainter extends CustomPainter {
  final String style; // round | shades | heart | star
  final Offset eyeL, eyeR; // fractions of the canvas
  const GlassesPainter(this.style, this.eyeL, this.eyeR);

  @override
  void paint(Canvas canvas, Size size) {
    final l = Offset(eyeL.dx * size.width, eyeL.dy * size.height);
    final r = Offset(eyeR.dx * size.width, eyeR.dy * size.height);
    final d = (r - l).distance;
    if (d <= 0) return;
    final dir = (r - l) / d;
    final tilt = math.atan2(r.dy - l.dy, r.dx - l.dx);
    final rad = d * .37;
    final sw = rad * .2;

    Color frame, lens;
    switch (style) {
      case 'shades':
        frame = const Color(0xFF1C1C2E);
        lens = const Color(0xE61C1C2E);
        break;
      case 'heart':
        frame = const Color(0xFFFF4F86);
        lens = const Color(0x55FF9DBD);
        break;
      case 'star':
        frame = const Color(0xFFFFB400);
        lens = const Color(0x55FFE066);
        break;
      default: // round
        frame = const Color(0xFF3A2A1E);
        lens = const Color(0x2EFFFFFF);
    }
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = frame;

    Path lensShape() {
      switch (style) {
        case 'shades':
          return Path()
            ..addRRect(RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset.zero, width: rad * 2.35, height: rad * 1.6),
                Radius.circular(rad * .62)));
        case 'heart':
          return heartPath(0, rad * .1, rad * 1.08);
        case 'star':
          return starPath(0, rad * .08, rad * 1.32, .52);
        default:
          return Path()
            ..addOval(Rect.fromCircle(center: Offset.zero, radius: rad));
      }
    }

    // bridge and little side arms first, so lenses sit on top of them
    final reach = style == 'shades' ? rad * 1.15 : rad * .95;
    canvas.drawLine(l + dir * reach, r - dir * reach, framePaint);
    for (final side in [-1.0, 1.0]) {
      final eye = side < 0 ? l : r;
      final start = eye + dir * (side * reach);
      final end = start + dir * (side * rad * .75) + Offset(0, -rad * .1);
      canvas.drawLine(start, end, framePaint);
    }

    for (final c in [l, r]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(tilt);
      final shape = lensShape();
      canvas.drawPath(shape, Paint()..color = lens);
      canvas.drawPath(shape, framePaint);
      // a little shine
      final shine = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = sw * .65
        ..color = Colors.white.withValues(alpha: style == 'shades' ? .55 : .8);
      canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: rad * .62),
          math.pi * 1.08,
          math.pi * .34,
          false,
          shine);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GlassesPainter old) =>
      old.style != style || old.eyeL != eyeL || old.eyeR != eyeR;
}

// ---------------------------------------------------------------------------
// Scarves: a wrap around the neck with a tail hanging down on one side.
// ---------------------------------------------------------------------------
class ScarfPainter extends CustomPainter {
  final String style; // red | green | rainbow
  final Offset center; // fraction of the canvas
  final double width; // fraction of the canvas width
  final double tilt;
  const ScarfPainter(this.style, this.center, this.width, this.tilt);

  static const _rainbow = [
    Color(0xFFFF5252),
    Color(0xFFFF9F2E),
    Color(0xFFFFD83D),
    Color(0xFF4CCB5A),
    Color(0xFF3E9BFF),
    Color(0xFFA25CFF),
  ];

  List<Color> get _colors {
    switch (style) {
      case 'green':
        return const [Color(0xFF3FB86B), Color(0xFFF6FFF0)];
      case 'rainbow':
        return _rainbow;
      default:
        return const [Color(0xFFE4405A), Color(0xFFCF3550)];
    }
  }

  // 'across' = bars run across the scarf, 'along' = bars run along its length
  bool get _along => style == 'rainbow';

  /// Paints [shape] filled with the scarf's stripes, light on top, shade below.
  /// The wrap (isTail == false) sags in the middle by [dip]; [strip] gives a
  /// slice of it (fractions of its height) that follows that curve.
  void _fill(Canvas canvas, Path shape,
      {required bool isTail,
      required double u,
      required double bandH,
      required double dip}) {
    final colors = _colors;
    final b = shape.getBounds();
    final reach = u / 2 + bandH / 2;

    Path strip(double f0, double f1) {
      if (isTail) {
        return Path()
          ..addRect(Rect.fromLTRB(
              b.left, b.top + b.height * f0, b.right, b.top + b.height * f1));
      }
      const steps = 24;
      final path = Path();
      for (var k = 0; k <= steps; k++) {
        final x = -reach + 2 * reach * k / steps;
        final q = 2 * x / u;
        final y = -bandH / 2 + bandH * f0 + dip * (1 - q * q);
        if (k == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      for (var k = steps; k >= 0; k--) {
        final x = -reach + 2 * reach * k / steps;
        final q = 2 * x / u;
        path.lineTo(x, -bandH / 2 + bandH * f1 + dip * (1 - q * q));
      }
      return path..close();
    }

    canvas.save();
    canvas.clipPath(shape);
    final paint = Paint();
    // For the wrap the length is horizontal, for the tail it is vertical.
    final barsVertical = isTail ? _along : !_along;
    if (barsVertical) {
      final period = _along ? b.width / colors.length : u * .075;
      var x = b.left;
      var i = 0;
      while (x < b.right) {
        paint.color = colors[i % colors.length];
        canvas.drawRect(
            Rect.fromLTWH(x, b.top - 1, period + .5, b.height + 2), paint);
        x += period;
        i++;
      }
    } else if (isTail) {
      final period = _along ? b.height / colors.length : u * .075;
      var y = b.top;
      var i = 0;
      while (y < b.bottom) {
        paint.color = colors[i % colors.length];
        canvas.drawRect(
            Rect.fromLTWH(b.left, y, b.width, period + .5), paint);
        y += period;
        i++;
      }
    } else {
      // rainbow wrap: stripes that follow the curve of the neck
      for (var i = 0; i < colors.length; i++) {
        paint.color = colors[i];
        canvas.drawPath(strip(i / colors.length, (i + 1) / colors.length), paint);
      }
    }
    // soft light on top, shade at the bottom
    canvas.drawPath(strip(0, .35),
        Paint()..color = Colors.white.withValues(alpha: .16));
    canvas.drawPath(strip(.78, 1.0),
        Paint()..color = Colors.black.withValues(alpha: .08));
    canvas.restore();
    canvas.drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * .028
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF3A2433).withValues(alpha: .6));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width * width;
    if (u <= 0) return;
    canvas.save();
    canvas.translate(center.dx * size.width, center.dy * size.height);
    canvas.rotate(tilt);

    final bandH = u * .30;
    final dip = bandH * .38; // how far the wrap sags in the middle
    final r = Radius.circular(bandH / 2);
    // a band whose middle sags and whose ends curve up round the neck
    final band = Path()
      ..moveTo(-u / 2, -bandH / 2)
      ..quadraticBezierTo(0, -bandH / 2 + 2 * dip, u / 2, -bandH / 2)
      ..arcToPoint(Offset(u / 2, bandH / 2), radius: r)
      ..quadraticBezierTo(0, bandH / 2 + 2 * dip, -u / 2, bandH / 2)
      ..arcToPoint(Offset(-u / 2, -bandH / 2), radius: r)
      ..close();
    final tailRect =
        Rect.fromLTWH(u * .13, bandH * .1, u * .27, u * .52);
    final tail = Path()
      ..addRRect(RRect.fromRectAndRadius(tailRect, Radius.circular(u * .07)));

    // the tail hangs a little crooked, and sits behind the wrap
    canvas.save();
    canvas.translate(tailRect.left, tailRect.top);
    canvas.rotate(.09);
    canvas.translate(-tailRect.left, -tailRect.top);
    _fill(canvas, tail, isTail: true, u: u, bandH: bandH, dip: 0);
    final fringe = Paint()
      ..strokeWidth = u * .03
      ..strokeCap = StrokeCap.round
      ..color = _colors.first;
    for (var i = 0; i < 4; i++) {
      final x = tailRect.left + tailRect.width * (.15 + i * .23);
      canvas.drawLine(
          Offset(x, tailRect.bottom), Offset(x, tailRect.bottom + u * .07), fringe);
    }
    canvas.restore();

    _fill(canvas, band, isTail: false, u: u, bandH: bandH, dip: dip);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScarfPainter old) =>
      old.style != style ||
      old.center != center ||
      old.width != width ||
      old.tilt != tilt;
}

// ---------------------------------------------------------------------------
// The avatar itself
// ---------------------------------------------------------------------------

/// The round character picture, wearing whatever is in [look].
///
/// With [animateItems] on, an item that has just been put on pops or drops
/// into place (the hat drops from above and bounces onto the head).
class FoxAvatar extends StatelessWidget {
  final String character;
  final double size;
  final FoxLook look;
  final bool animateItems;
  const FoxAvatar(
      {super.key,
      required this.character,
      this.size = 70,
      this.look = FoxLook.none,
      this.animateItems = false});

  Duration get _dur =>
      animateItems ? const Duration(milliseconds: 750) : Duration.zero;

  /// Glasses / scarf: a springy pop-in around the spot they belong to.
  Widget _pop(ShopItem item, Offset origin, Widget child) =>
      TweenAnimationBuilder<double>(
          key: ValueKey('${item.slot.name}-${item.style}'),
          tween: Tween<double>(begin: 0, end: 1),
          duration: _dur,
          curve: Curves.elasticOut,
          child: child,
          builder: (_, v, child) => Opacity(
              opacity: (v * 4).clamp(0.0, 1.0).toDouble(),
              child: Transform.scale(
                  scale: .4 + .6 * v,
                  alignment: Alignment(origin.dx * 2 - 1, origin.dy * 2 - 1),
                  child: child)));

  Widget _hat(ShopItem item, _Anchor a, double p) {
    final cx = 5 + a.hat.dx * p, base = 5 + a.hat.dy * p;
    final w = a.hatW * p;
    final painted = item.style != 'emoji';
    final double boxW = painted ? w * 1.25 : w * 1.7;
    final double boxH = painted ? boxW * 1.1 : w * 1.5;
    // painted hats: brim middle is 82% down the box. Emoji: sit on the head.
    final top = painted ? base - boxH * .82 : base - w * .42 - boxH / 2;
    final Widget art = painted
        ? CustomPaint(size: Size(boxW, boxH), painter: const MagicHatPainter())
        : Center(
            child: Text(item.emoji,
                style: TextStyle(fontSize: w * 1.02, height: 1)));
    return Positioned(
        left: cx - boxW / 2,
        top: top,
        width: boxW,
        height: boxH,
        child: TweenAnimationBuilder<double>(
            key: ValueKey('${item.slot.name}-${item.style}'),
            tween: Tween<double>(begin: 0, end: 1),
            duration: _dur,
            curve: Curves.bounceOut,
            child: art,
            builder: (_, v, child) => Opacity(
                opacity: (v * 6).clamp(0.0, 1.0).toDouble(),
                child: Transform.translate(
                    offset: Offset(0, -(1 - v) * p * .6),
                    child: Transform.rotate(
                        angle: a.tilt * .7,
                        alignment: const Alignment(0, .6),
                        child: child)))));
  }

  @override
  Widget build(BuildContext context) {
    final p = size - 10;
    final a = _anchors[character] ?? _anchors['fox']!;
    // fur and eye colours are baked pictures (assets/pets/) for all four
    final known = _anchors.containsKey(character);
    final fur = known ? look.fur : null;
    final eyes = known ? look.eyes : null;
    return SizedBox(
        width: size,
        height: size,
        // clipBehavior.none lets the hat sit above the circle instead of
        // being cropped at the avatar's own edge.
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF77CEF9), width: 3)),
              padding: const EdgeInsets.all(5),
              child: ClipOval(
                  child: SizedBox(
                      width: p,
                      height: p,
                      child: Stack(fit: StackFit.expand, children: [
                        if (fur == null)
                          WordPicture(character, size: p)
                        else
                          Image.asset('assets/pets/${character}_fur_${fur.style}.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium),
                        if (eyes != null)
                          Image.asset('assets/pets/${character}_eyes_${eyes.style}.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium),
                        if (look.scarf != null)
                          _pop(
                              look.scarf!,
                              a.neck,
                              CustomPaint(
                                  painter: ScarfPainter(look.scarf!.style,
                                      a.neck, a.scarfW, a.tilt * .6))),
                        if (look.glasses != null)
                          _pop(
                              look.glasses!,
                              Offset((a.eyeL.dx + a.eyeR.dx) / 2,
                                  (a.eyeL.dy + a.eyeR.dy) / 2),
                              CustomPaint(
                                  painter: GlassesPainter(
                                      look.glasses!.style, a.eyeL, a.eyeR))),
                      ])))),
          if (look.hat != null) _hat(look.hat!, a, p),
        ]));
  }
}

// ---------------------------------------------------------------------------
// Little pictures of items, for the shop cards
// ---------------------------------------------------------------------------
class ItemArt extends StatelessWidget {
  final ShopItem item;
  final double size;
  const ItemArt(this.item, {super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    switch (item.slot) {
      case ShopSlot.hat:
        if (item.style == 'emoji') {
          return SizedBox(
              height: size,
              child: Center(
                  child: Text(item.emoji,
                      style: TextStyle(fontSize: size * .85, height: 1))));
        }
        return SizedBox(
            width: size * .95,
            height: size,
            child: const CustomPaint(painter: MagicHatPainter()));
      case ShopSlot.glasses:
        return SizedBox(
            width: size * 1.45,
            height: size * .8,
            child: CustomPaint(
                painter: GlassesPainter(
                    item.style, const Offset(.27, .5), const Offset(.73, .5))));
      case ShopSlot.scarf:
        return SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
                painter:
                    ScarfPainter(item.style, const Offset(.46, .3), .84, 0)));
      case ShopSlot.fur:
        return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                gradient: RadialGradient(
                    center: const Alignment(-.3, -.4),
                    colors: [
                      Color.lerp(Color(item.color), Colors.white, .35)!,
                      Color(item.color)
                    ]),
                boxShadow: [
                  BoxShadow(
                      color: Color(item.color).withValues(alpha: .4),
                      blurRadius: 8,
                      offset: const Offset(0, 3))
                ]),
            child: Icon(Icons.pets, color: Colors.white, size: size * .5));
      case ShopSlot.eyes:
        final iris = Color(item.color);
        return Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE0DCCB), width: 2)),
            child: Container(
                width: size * .68,
                height: size * .68,
                decoration: BoxDecoration(shape: BoxShape.circle, color: iris),
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                      width: size * .36,
                      height: size * .36,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF14141F))),
                  Positioned(
                      top: size * .12,
                      left: size * .16,
                      child: Container(
                          width: size * .13,
                          height: size * .13,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.white)))
                ])));
    }
  }
}
