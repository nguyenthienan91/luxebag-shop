import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Generate Icon', (WidgetTester tester) async {
    final imageBytes = File('assets/bag_only.png').readAsBytesSync();
    final imageCodec = await ui.instantiateImageCodec(imageBytes);
    final frameInfo = await imageCodec.getNextFrame();
    final bagImage = frameInfo.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 1024, 1024));

    // Fill white background
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 1024), paint);

    // Draw bag image centered at top half (make it larger)
    final src = Rect.fromLTWH(0, 0, bagImage.width.toDouble(), bagImage.height.toDouble());
    
    // We want the bag to be around 900 wide, centered
    double targetWidth = 1000;
    double targetHeight = 1000 * bagImage.height / bagImage.width;
    double xOffset = (1024 - targetWidth) / 2;
    // Push it up a bit since text is at the bottom
    double yOffset = 0;
    
    final dst = Rect.fromLTWH(xOffset, yOffset, targetWidth, targetHeight);
    canvas.drawImageRect(bagImage, src, dst, Paint());

    // Draw LuxeBag text
    final textStyle = const TextStyle(
      color: Colors.black87,
      fontSize: 130,
      fontWeight: FontWeight.w900,
      fontFamily: 'Roboto',
      letterSpacing: -2,
    );
    final textSpan = TextSpan(text: 'LuxeBag', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(minWidth: 1024, maxWidth: 1024);
    // Draw text
    textPainter.paint(canvas, const Offset(0, 720));

    // Draw Slogan text
    final sloganStyle = const TextStyle(
      color: Colors.black54,
      fontSize: 45,
      fontWeight: FontWeight.w600,
      fontFamily: 'Roboto',
      letterSpacing: 8,
    );
    final sloganSpan = TextSpan(text: 'PREMIUM BAGS', style: sloganStyle);
    final sloganPainter = TextPainter(
      text: sloganSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    sloganPainter.layout(minWidth: 1024, maxWidth: 1024);
    sloganPainter.paint(canvas, const Offset(0, 890));

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(1024, 1024);
    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    
    File('assets/icon_final.png').writeAsBytesSync(byteData!.buffer.asUint8List());
    print('Final icon generated successfully.');
  });
}
