import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Calls parallel method to convert image from [CameraImage] type into [InputImage] type.
Future<void> processCameraImage(ReceivePort rp, CameraImage image) async {
  final message = {
    "sendport": rp.sendPort,
    "image": image,
  };

  await Isolate.spawn(_processCameraImage, message);
}

/// Converts image from [CameraImage] type into [InputImage] type.
void _processCameraImage(Map<String, dynamic> message) async {
  final SendPort sp = message["sendport"];
  final CameraImage image = message["image"];

  final WriteBuffer allBytes = WriteBuffer();
  for (Plane plane in image.planes) {
    allBytes.putUint8List(plane.bytes);
  }
  final bytes = allBytes.done().buffer.asUint8List();

  final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
  const imageRotation = InputImageRotation.rotation0deg;
  final inputImageFormat =
      InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

  final planeData = image.planes.first.bytesPerRow;

  final inputImageData = InputImageMetadata(
    size: imageSize,
    rotation: imageRotation,
    format: inputImageFormat,
    bytesPerRow: planeData,
  );

  final InputImage inputImage =
      InputImage.fromBytes(bytes: bytes, metadata: inputImageData);

  Isolate.exit(sp, inputImage);
}
