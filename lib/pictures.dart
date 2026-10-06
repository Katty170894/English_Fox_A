import 'package:flutter/material.dart';
import 'word_assets.dart';

const animalTiles = {
  'fox': 0,
  'rabbit': 1,
  'bear': 2,
  'cat': 3,
  'dog': 4,
  'bird': 5,
  'fish': 6,
  'cow': 7,
  'lion': 8,
  'tiger': 9,
  'monkey': 10,
  'elephant': 11,
  'zebra': 12,
  'giraffe': 13,
  'bee': 14,
  'butterfly': 15
};
const foodTiles = {
  'apple': 0,
  'banana': 1,
  'orange': 2,
  'pear': 3,
  'grape': 4,
  'watermelon': 5,
  'bread': 6,
  'milk': 7,
  'juice': 8,
  'cake': 9,
  'cheese': 10,
  'egg': 11,
  'pizza': 12,
  'burger': 13,
  'ice cream': 14,
  'cookie': 15
};
const wordColors = {
  'red': Colors.red,
  'blue': Colors.blue,
  'yellow': Colors.amber,
  'green': Colors.green,
  'pink': Colors.pinkAccent,
  'purple': Colors.purple,
  'orange': Colors.orange
};
const numberWords = [
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten'
];
const drawnWords = {
  'in',
  'on',
  'under',
  'next to',
  'big',
  'small',
  'long',
  'short',
  'circle',
  'square',
  'triangle',
  'Mars',
  'crater',
  'cave',
  'pond',
  'river',
  'table'
};

class AtlasPicture extends StatelessWidget {
  final String asset;
  final int index;
  final double size;
  const AtlasPicture(
      {super.key,
      required this.asset,
      required this.index,
      required this.size});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: size,
      height: size,
      child: ClipRect(
          child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: size * 4,
              maxWidth: size * 4,
              minHeight: size * 4,
              maxHeight: size * 4,
              child: Transform.translate(
                  offset: Offset(-(index % 4) * size, -(index ~/ 4) * size),
                  child: Image.asset(asset,
                      width: size * 4,
                      height: size * 4,
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.medium)))));
}

class WordPicture extends StatelessWidget {
  final String word;
  final double size;
  final bool colorMeaning;
  const WordPicture(this.word,
      {super.key, this.size = 100, this.colorMeaning = false});
  static bool supports(String w) =>
      animalTiles.containsKey(w) ||
      foodTiles.containsKey(w) ||
      wordAssets.containsKey(w) ||
      wordColors.containsKey(w) ||
      numberWords.contains(w) ||
      drawnWords.contains(w);
  @override
  Widget build(BuildContext context) {
    Widget child;
    if (wordColors.containsKey(word) && (word != 'orange' || colorMeaning)) {
      child = Padding(
          padding: EdgeInsets.all(size * .12),
          child: DecoratedBox(
              decoration: BoxDecoration(
                  color: wordColors[word],
                  shape: BoxShape.circle,
                  boxShadow: [
                BoxShadow(
                    color: wordColors[word]!.withValues(alpha: .25),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ])));
    } else if (animalTiles.containsKey(word)) {
      child = AtlasPicture(
          asset: 'assets/animals-atlas.png',
          index: animalTiles[word]!,
          size: size);
    } else if (foodTiles.containsKey(word)) {
      child = AtlasPicture(
          asset: 'assets/food-atlas.png', index: foodTiles[word]!, size: size);
    } else if (drawnWords.contains(word) || numberWords.contains(word)) {
      child = CustomPaint(painter: _MeaningPainter(word));
    } else {
      child = Image.asset(wordAssets[word]!,
          fit: BoxFit.contain, filterQuality: FilterQuality.medium);
    }
    return Semantics(
        label: 'Picture: $word',
        image: true,
        child: SizedBox(width: size, height: size, child: child));
  }
}

class _MeaningPainter extends CustomPainter {
  final String word;
  _MeaningPainter(this.word);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final p = Paint()..isAntiAlias = true;
    void circle(double x, double y, double r, Color c) {
      p.color = c;
      canvas.drawCircle(Offset(x, y), r, p);
    }

    void rect(double x, double y, double w, double h, Color c) {
      p.color = c;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x, y, w, h), const Radius.circular(4)),
          p);
    }

    final n = numberWords.indexOf(word) + 1;
    if (n > 0) {
      // Bigger dots when there are fewer of them, so "one" or "two" don't
      // shrink down to a barely-visible speck in small thumbnails.
      final r = n <= 2
          ? 15.0
          : n <= 4
              ? 11.0
              : 8.0;
      final spacing = r * 2.2;
      for (var i = 0; i < n; i++) {
        final cols = n < 5 ? n : 5;
        circle(50 - (cols - 1) * spacing / 2 + (i % cols) * spacing,
            n > 5 ? 40 + (i ~/ 5) * 20 : 50, r, Colors.orange);
      }
    } else if (['in', 'on', 'under', 'next to'].contains(word)) {
      rect(20, 48, 48, 25, const Color(0xFFC48C55));
      rect(20, 70, 6, 16, Colors.brown);
      rect(62, 70, 6, 16, Colors.brown);
      final ball = switch (word) {
        'on' => const Offset(44, 38),
        'under' => const Offset(44, 85),
        'next to' => const Offset(83, 62),
        _ => const Offset(44, 58)
      };
      circle(ball.dx, ball.dy, 9, Colors.blue);
      if (word == 'in') {
        rect(20, 65, 48, 10, const Color(0xFFE3B476));
      }
    } else if (word == 'big' || word == 'small') {
      circle(30, 55, word == 'big' ? 23 : 10, Colors.orange);
      circle(77, 55, word == 'big' ? 10 : 23, const Color(0xFFDDEAF0));
    } else if (word == 'long' || word == 'short') {
      rect(12, 30, word == 'long' ? 78 : 30, 13, Colors.orange);
      rect(12, 60, word == 'long' ? 30 : 78, 13, const Color(0xFFDDEAF0));
    } else if (word == 'circle') {
      circle(50, 50, 32, Colors.blue);
    } else if (word == 'square') {
      rect(20, 20, 60, 60, Colors.green);
    } else if (word == 'triangle') {
      p.color = Colors.deepOrange;
      canvas.drawPath(
          Path()
            ..moveTo(50, 13)
            ..lineTo(88, 80)
            ..lineTo(12, 80)
            ..close(),
          p);
    } else if (word == 'table') {
      rect(12, 35, 76, 14, Colors.brown);
      rect(19, 49, 9, 36, Colors.brown);
      rect(73, 49, 9, 36, Colors.brown);
    } else if (word == 'Mars') {
      circle(50, 50, 34, const Color(0xFFE87547));
      circle(37, 37, 7, const Color(0xFFB95739));
      circle(64, 59, 11, const Color(0xFFC9603B));
      circle(34, 67, 5, const Color(0xFFB95739));
    } else if (word == 'crater') {
      p.color = const Color(0xFFB3B8C5);
      canvas.drawOval(const Rect.fromLTWH(8, 35, 84, 40), p);
      p.color = const Color(0xFF5D667C);
      canvas.drawOval(const Rect.fromLTWH(22, 39, 55, 23), p);
    } else if (word == 'cave') {
      p.color = const Color(0xFF9C958F);
      canvas.drawPath(
          Path()
            ..moveTo(8, 85)
            ..lineTo(25, 31)
            ..lineTo(49, 15)
            ..lineTo(72, 31)
            ..lineTo(93, 85)
            ..close(),
          p);
      p.color = const Color(0xFF344354);
      canvas.drawOval(const Rect.fromLTWH(33, 43, 36, 45), p);
      rect(7, 83, 87, 6, Colors.green);
    } else {
      rect(2, 2, 96, 96, const Color(0xFFDDF4CE));
      p.color = const Color(0xFF40C7EB);
      if (word == 'pond') {
        canvas.drawOval(const Rect.fromLTWH(12, 28, 76, 44), p);
      } else {
        final path = Path()
          ..moveTo(22, 0)
          ..cubicTo(80, 20, 5, 60, 50, 100)
          ..lineTo(82, 100)
          ..cubicTo(36, 60, 100, 20, 54, 0)
          ..close();
        canvas.drawPath(path, p);
      }
      for (var i = 0; i < 3; i++) {
        circle(15 + i * 33, 12, 5, Colors.green);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MeaningPainter oldDelegate) =>
      oldDelegate.word != word;
}
