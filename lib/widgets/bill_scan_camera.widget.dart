import 'dart:async';
import 'dart:isolate';

import 'package:barcode_bill_scanner/util/process_image.isolate.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_barcode_kit/google_barcode_kit.dart';
import 'package:rxdart/rxdart.dart';

/// Widget used to read the barcode using phone's camera.
class BillScanCameraWidget extends StatefulWidget {
  const BillScanCameraWidget({
    Key? key,
    required this.onImage,
    this.initialDirection = CameraLensDirection.back,
  }) : super(key: key);

  final Function(List<Barcode> barcodes) onImage;
  final CameraLensDirection initialDirection;

  @override
  BillScanCameraWidgetState createState() => BillScanCameraWidgetState();
}

class BillScanCameraWidgetState extends State<BillScanCameraWidget> {
  /// Camera list.
  List<CameraDescription> cameras = [];

  /// Controller for the camera.
  CameraController? cameraController;

  /// Stream of images to be processed.
  final StreamController<CameraImage> streamController = StreamController<CameraImage>();

  /// Subscription of images being processed.
  late final StreamSubscription streamSubscription;

  /// Port used to receive processed images.
  final ReceivePort receivePort = ReceivePort('imageProcessPort');

  /// Camera being used for scanning.
  int? _cameraIndex;

  /// Zoom levels.
  double zoomLevel = 1.0, minZoomLevel = 0.0;

  /// Scanner for reading barcode images.
  final BarcodeScanner barcodeScanner = GoogleMlKit.vision.barcodeScanner([
    BarcodeFormat.itf,
    BarcodeFormat.codabar,
  ]);

  @override
  void initState() {
    super.initState();
    initStreams();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    cameras = await availableCameras();
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == widget.initialDirection && _cameraIndex == null) {
        _cameraIndex = i;
      }
    }

    startLiveFeed();
  }

  @override
  void dispose() {
    stopLiveFeed();
    super.dispose();
    streamSubscription.cancel();
    streamController.close();
  }

  @override
  Widget build(BuildContext context) {
    return cameraController?.value.isInitialized == true
        ? Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.black,
            child: Center(child: CameraPreview(cameraController!)),
          )
        : Container();
  }

  /// Initialize event streams used to process camera images.
  void initStreams() {
    // buffers livestream to process only one image per second.
    // sends a message to parallel processing.
    streamSubscription = streamController.stream
        .bufferTime(const Duration(seconds: 1))
        .where((imageList) => imageList.isNotEmpty)
        .map((imageList) => imageList.last)
        .listen(convertsCameraImage);

    // translates incoming images to barcode.
    // receives a message from parallel processing.
    receivePort
        .asBroadcastStream()
        .whereType<InputImage>()
        .asyncMap((InputImage inputImage) => barcodeScanner.processImage(inputImage))
        .where((List<Barcode> barcodeList) => barcodeList.isNotEmpty)
        .listen(widget.onImage);
  }

  /// Begins camera livestream.
  Future<void> startLiveFeed() async {
    final camera = cameras[_cameraIndex ?? 0];
    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController?.initialize();

    if (!mounted) return;

    cameraController?.getMinZoomLevel().then((value) {
      zoomLevel = value;
      minZoomLevel = value;
    });

    cameraController?.setZoomLevel(zoomLevel > minZoomLevel ? zoomLevel : minZoomLevel);

    cameraController?.lockCaptureOrientation(DeviceOrientation.portraitUp);
    cameraController?.startImageStream(streamController.add);
    setState(() {});
  }

  /// Stops camera livestream.
  Future stopLiveFeed() async {
    await cameraController?.stopImageStream();
    await cameraController?.dispose();
  }

  /// Sends captured image to be converted from [CameraImage] type into [InputImage] type.
  ///
  /// The converted imaged is received by [listenBarcodes] method.
  Future<void> convertsCameraImage(CameraImage image) async {
    processCameraImage(receivePort, image);
  }
}
