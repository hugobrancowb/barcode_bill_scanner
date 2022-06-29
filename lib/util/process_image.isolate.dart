import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_barcode_kit/google_barcode_kit.dart';

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
  const imageRotation = InputImageRotation.Rotation_0deg;
  final inputImageFormat =
      InputImageFormatMethods.fromRawValue(image.format.raw) ?? InputImageFormat.NV21;

  final planeData = image.planes.map(
    (Plane plane) {
      return InputImagePlaneMetadata(
        bytesPerRow: plane.bytesPerRow,
        height: plane.height,
        width: plane.width,
      );
    },
  ).toList();

  final inputImageData = InputImageData(
    size: imageSize,
    imageRotation: imageRotation,
    inputImageFormat: inputImageFormat,
    planeData: planeData,
  );

  final InputImage inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

  Isolate.exit(sp, inputImage);
}
