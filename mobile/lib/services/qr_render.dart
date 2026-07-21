import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image/image.dart' as img;

class QrRender {
  static Future<Uint8List> toJpg(String data, {int size = 480, int quality = 92}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: false,
    );
    final pngBytes = await painter.toImageData(size.toDouble(), format: ui.ImageByteFormat.png);
    if (pngBytes == null) throw Exception("Failed to render QR image");
    final image = img.decodePng(pngBytes.buffer.asUint8List(pngBytes.offsetInBytes, pngBytes.lengthInBytes));
    if (image == null) throw Exception("Failed to decode PNG from QR render");
    return Uint8List.fromList(img.encodeJpg(image, quality: quality));
  }

  static Future<Uint8List> toPng(String data, {int size = 480}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: false,
    );
    final pngBytes = await painter.toImageData(size.toDouble(), format: ui.ImageByteFormat.png);
    if (pngBytes == null) throw Exception("Failed to render QR image");
    return pngBytes.buffer.asUint8List(pngBytes.offsetInBytes, pngBytes.lengthInBytes);
  }

  static Future<Uint8List> render(String data, {int size = 480}) => toJpg(data, size: size);
}
