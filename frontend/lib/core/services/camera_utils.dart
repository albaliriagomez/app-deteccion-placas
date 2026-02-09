import 'dart:typed_data';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Convert CameraImage (YUV420) to NV21 bytes and build InputImage for ML Kit
InputImage? convertCameraImageToInputImage(CameraImage image, int rotation) {
  try {
    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final nv21 = _convertYUV420ToNV21(image);

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg,
      format: InputImageFormat.nv21,
      bytesPerRow: image.planes.isNotEmpty ? image.planes[0].bytesPerRow : image.width,
    );

    return InputImage.fromBytes(bytes: nv21, metadata: inputImageData);
  } catch (e) {
    return null;
  }
}

Uint8List _convertYUV420ToNV21(CameraImage image) {
  final int width = image.width;
  final int height = image.height;
  final int ySize = width * height;
  final int uvSize = width * height ~/ 2;
  final nv21 = Uint8List(ySize + uvSize);

  // Copy Y plane
  final planeY = image.planes[0];
  if (planeY.bytesPerRow == width) {
    // Continuous Y
    nv21.setRange(0, ySize, planeY.bytes);
  } else {
    // Copy row by row
    var dst = 0;
    for (var row = 0; row < height; row++) {
      nv21.setRange(dst, dst + width, planeY.bytes, row * planeY.bytesPerRow);
      dst += width;
    }
  }

  // Interleave V and U (NV21 = VU)
  final planeU = image.planes.length > 1 ? image.planes[1] : null;
  final planeV = image.planes.length > 2 ? image.planes[2] : null;

  var offset = ySize;
  if (planeU != null && planeV != null) {
    final uvRowStride = planeU.bytesPerRow;
    final uvPixelStride = planeU.bytesPerPixel ?? 1;

    final int halfHeight = (height / 2).floor();
    final int halfWidth = (width / 2).floor();

    for (var row = 0; row < halfHeight; row++) {
      for (var col = 0; col < halfWidth; col++) {
        final uIndex = row * uvRowStride + col * uvPixelStride;
        final vIndex = row * planeV.bytesPerRow + col * (planeV.bytesPerPixel ?? 1);
        nv21[offset++] = planeV.bytes[vIndex];
        nv21[offset++] = planeU.bytes[uIndex];
      }
    }
  }

  return nv21;
}
