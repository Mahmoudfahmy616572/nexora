import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final sizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  for (final entry in sizes.entries) {
    final size = entry.value;
    final icon = _generateIcon(size);
    final dir = Directory('android/app/src/main/res/mipmap-${entry.key}');
    dir.createSync(recursive: true);
    final file = File('${dir.path}/ic_launcher.png');
    file.writeAsBytesSync(img.encodePng(icon));
    print('Generated ${entry.key}: ${size}x${size} -> ${file.path}');
  }

  // Also generate round icon
  for (final entry in sizes.entries) {
    final size = entry.value;
    final icon = _generateRoundIcon(size);
    final dir = Directory('android/app/src/main/res/mipmap-${entry.key}');
    dir.createSync(recursive: true);
    final file = File('${dir.path}/ic_launcher_round.png');
    file.writeAsBytesSync(img.encodePng(icon));
    print('Generated round ${entry.key}: ${size}x${size} -> ${file.path}');
  }

  print('Done!');
}

img.Image _generateIcon(int size) {
  final canvas = img.Image(width: size, height: size);

  // Fill background with dark navy
  img.fill(canvas, color: img.ColorRgb8(13, 17, 23));

  // Draw rounded rectangle background
  _drawRoundedRect(canvas, 0, 0, size, size, size * 0.22,
      img.ColorRgb8(13, 17, 23));

  // Draw subtle gradient overlay on background
  for (var y = 0; y < size; y++) {
    final t = y / size;
    final r = (13 + t * 8).toInt();
    final g = (17 + t * 12).toInt();
    final b = (23 + t * 20).toInt();
    for (var x = 0; x < size; x++) {
      if (_isInsideRoundedRect(x, y, size, size, size * 0.22)) {
        canvas.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }

  // Draw the stylized "N"
  final padding = size * 0.25;
  final nLeft = padding;
  final nRight = size - padding;
  final nTop = padding * 1.1;
  final nBottom = size - padding * 1.1;

  // Gradient colors for the N strokes
  final colorTop = img.ColorRgb8(0, 212, 170);    // #00D4AA teal
  final colorBottom = img.ColorRgb8(8, 145, 178);  // #0891B2 cyan
  final glowColor = img.ColorRgb8(0, 212, 170);

  // Draw glow effect behind N
  final strokeWidth = (size * 0.06).ceil();
  final glowWidth = (size * 0.15).ceil();

  // Glow for left vertical
  _drawGlowLine(canvas, nLeft, nTop, nLeft, nBottom, glowWidth, glowColor);
  // Glow for right vertical
  _drawGlowLine(canvas, nRight, nTop, nRight, nBottom, glowWidth, glowColor);
  // Glow for diagonal
  _drawGlowLine(canvas, nLeft, nTop, nRight, nBottom, glowWidth, glowColor);

  // Left vertical stroke
  _drawThickLine(canvas, nLeft, nTop, nLeft, nBottom, strokeWidth, colorTop);
  // Right vertical stroke
  _drawThickLine(canvas, nRight, nTop, nRight, nBottom, strokeWidth, colorBottom);

  // Diagonal stroke (top-left to bottom-right)
  _drawDiagonalGradient(canvas, nLeft, nTop, nRight, nBottom, strokeWidth, colorTop, colorBottom);

  // Draw nodes (circles) at the 4 corners of the N
  final nodeRadius = (size * 0.04).ceil();
  _drawCircle(canvas, nLeft.toInt(), nTop.toInt(), nodeRadius, img.ColorRgb8(255, 255, 255));
  _drawCircle(canvas, nLeft.toInt(), nBottom.toInt(), nodeRadius, img.ColorRgb8(255, 255, 255));
  _drawCircle(canvas, nRight.toInt(), nTop.toInt(), nodeRadius, img.ColorRgb8(255, 255, 255));
  _drawCircle(canvas, nRight.toInt(), nBottom.toInt(), nodeRadius, img.ColorRgb8(255, 255, 255));

  // Draw small accent dots (circuit nodes)
  final accentRadius = (size * 0.015).ceil();
  final accentColor = img.ColorRgb8(0, 212, 170);
  _drawCircle(canvas, (nLeft + size * 0.08).toInt(), (nTop + size * 0.08).toInt(), accentRadius, accentColor);
  _drawCircle(canvas, (nRight - size * 0.08).toInt(), (nBottom - size * 0.08).toInt(), accentRadius, accentColor);

  return canvas;
}

img.Image _generateRoundIcon(int size) {
  final square = _generateIcon(size);
  final circle = img.Image(width: size, height: size);

  // Fill transparent
  img.fill(circle, color: img.ColorRgba8(0, 0, 0, 0));

  // Copy pixels inside a circle
  final cx = size / 2;
  final cy = size / 2;
  final radius = size / 2 - 1;

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        final pixel = square.getPixel(x, y);
        circle.setPixelRgba(x, y, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), 255);
      }
    }
  }

  return circle;
}

bool _isInsideRoundedRect(int x, int y, int w, int h, double radius) {
  if (x < radius && y < radius) {
    return (x - radius) * (x - radius) + (y - radius) * (y - radius) <= radius * radius;
  }
  if (x >= w - radius && y < radius) {
    return (x - (w - radius)) * (x - (w - radius)) + (y - radius) * (y - radius) <= radius * radius;
  }
  if (x < radius && y >= h - radius) {
    return (x - radius) * (x - radius) + (y - (h - radius)) * (y - (h - radius)) <= radius * radius;
  }
  if (x >= w - radius && y >= h - radius) {
    return (x - (w - radius)) * (x - (w - radius)) + (y - (h - radius)) * (y - (h - radius)) <= radius * radius;
  }
  return true;
}

void _drawRoundedRect(img.Image canvas, int x, int y, int w, int h, double radius, img.Color color) {
  for (var py = y; py < y + h; py++) {
    for (var px = x; px < x + w; px++) {
      if (_isInsideRoundedRect(px - x, py - y, w, h, radius)) {
        canvas.setPixelRgba(px, py, color.r.toInt(), color.g.toInt(), color.b.toInt(), 255);
      }
    }
  }
}

void _drawThickLine(img.Image canvas, double x1, double y1, double x2, double y2, int thickness, img.Color color) {
  final steps = ((x2 - x1).abs() > (y2 - y1).abs()) ? (x2 - x1).abs() : (y2 - y1).abs();
  if (steps == 0) return;
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = (x1 + (x2 - x1) * t).toInt();
    final y = (y1 + (y2 - y1) * t).toInt();
    _drawCircle(canvas, x, y, thickness ~/ 2, color);
  }
}

void _drawDiagonalGradient(img.Image canvas, double x1, double y1, double x2, double y2,
    int thickness, img.Color color1, img.Color color2) {
  final steps = ((x2 - x1).abs() > (y2 - y1).abs()) ? (x2 - x1).abs() : (y2 - y1).abs();
  if (steps == 0) return;
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = (x1 + (x2 - x1) * t).toInt();
    final y = (y1 + (y2 - y1) * t).toInt();
    final r = (color1.r + (color2.r - color1.r) * t).toInt();
    final g = (color1.g + (color2.g - color1.g) * t).toInt();
    final b = (color1.b + (color2.b - color1.b) * t).toInt();
    _drawCircle(canvas, x, y, thickness ~/ 2, img.ColorRgb8(r, g, b));
  }
}

void _drawGlowLine(img.Image canvas, double x1, double y1, double x2, double y2, int radius, img.Color color) {
  final steps = ((x2 - x1).abs() > (y2 - y1).abs()) ? (x2 - x1).abs() : (y2 - y1).abs();
  if (steps == 0) return;
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = (x1 + (x2 - x1) * t).toInt();
    final y = (y1 + (y2 - y1) * t).toInt();
    // Draw glow with fading alpha
    for (var r = radius; r > 0; r -= 2) {
      final alpha = (30 * (1 - r / radius)).toInt();
      if (alpha <= 0) continue;
      final glowColor = img.ColorRgba8(color.r.toInt(), color.g.toInt(), color.b.toInt(), alpha);
      _drawCircleAlpha(canvas, x, y, r, glowColor);
    }
  }
}

void _drawCircle(img.Image canvas, int cx, int cy, int radius, img.Color color) {
  for (var y = cy - radius; y <= cy + radius; y++) {
    for (var x = cx - radius; x <= cx + radius; x++) {
      if (x < 0 || x >= canvas.width || y < 0 || y >= canvas.height) continue;
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        canvas.setPixelRgba(x, y, color.r.toInt(), color.g.toInt(), color.b.toInt(), 255);
      }
    }
  }
}

void _drawCircleAlpha(img.Image canvas, int cx, int cy, int radius, img.ColorRgba8 color) {
  for (var y = cy - radius; y <= cy + radius; y++) {
    for (var x = cx - radius; x <= cx + radius; x++) {
      if (x < 0 || x >= canvas.width || y < 0 || y >= canvas.height) continue;
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        final existing = canvas.getPixel(x, y);
        final newAlpha = (color.a.toInt() + existing.a.toInt()).clamp(0, 255);
        canvas.setPixelRgba(x, y, color.r.toInt(), color.g.toInt(), color.b.toInt(), newAlpha);
      }
    }
  }
}
