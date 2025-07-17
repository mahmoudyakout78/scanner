import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';

Widget createOverlay(List<BarcodeResult> results) {
  return CustomPaint(
    painter: OverlayPainter(results),
  );
}

class OverlayPainter extends CustomPainter {
  final List<BarcodeResult> results;

  const OverlayPainter(this.results);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 233, 59, 46)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    for (var result in results) {
      print(result.toJson());
      double minX = result.x1.toDouble();
      double minY = result.y1.toDouble();
      if (result.x2 < minX) minX = result.x2.toDouble();
      if (result.x3 < minX) minX = result.x3.toDouble();
      if (result.x4 < minX) minX = result.x4.toDouble();
      if (result.y2 < minY) minY = result.y2.toDouble();
      if (result.y3 < minY) minY = result.y3.toDouble();
      if (result.y4 < minY) minY = result.y4.toDouble();

      canvas.drawLine(Offset(result.x1.toDouble(), result.y1.toDouble()),
          Offset(result.x2.toDouble(), result.y2.toDouble()), paint);
      canvas.drawLine(Offset(result.x2.toDouble(), result.y2.toDouble()),
          Offset(result.x3.toDouble(), result.y3.toDouble()), paint);
      canvas.drawLine(Offset(result.x3.toDouble(), result.y3.toDouble()),
          Offset(result.x4.toDouble(), result.y4.toDouble()), paint);
      canvas.drawLine(Offset(result.x4.toDouble(), result.y4.toDouble()),
          Offset(result.x1.toDouble(), result.y1.toDouble()), paint);

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: result.text,
          style: const TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontSize: 24.0,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(minWidth: 0, maxWidth: size.width);
      textPainter.paint(canvas, Offset(minX, minY - 30));
    }
  }

  @override
  bool shouldRepaint(OverlayPainter oldDelegate) =>
      results != oldDelegate.results;
}


class BarcodeOverlayWithToken extends StatelessWidget {
  final List<BarcodeResult> results;

  const BarcodeOverlayWithToken({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // overlay that shows the red boxes
        createOverlay(results),

        // positioned token display (bottom of the screen)
        if (results.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                for (var result in results)
                  ElevatedButton(
                    onPressed: () {
                      // Do something with the token
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => Container(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            "Token: ${result.text}",
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text("Token: ${result.text}"),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
