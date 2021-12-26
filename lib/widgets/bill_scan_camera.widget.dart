import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_barcode_kit/google_barcode_kit.dart';

/// Widget utilizado para leitura de código de barras através da câmera nativa.
class BillScanCameraWidget extends StatefulWidget {
  const BillScanCameraWidget({
    Key? key,
    this.title,
    required this.onImage,
    required this.color,
    this.initialDirection = CameraLensDirection.back,
  }) : super(key: key);

  final String? title;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialDirection;
  final Color color;

  @override
  _BillScanCameraWidgetState createState() => _BillScanCameraWidgetState();
}

class _BillScanCameraWidgetState extends State<BillScanCameraWidget> {
  List<CameraDescription> cameras = [];
  CameraController? _controller;
  int _cameraIndex = 0;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    cameras = await availableCameras();
    for (var i = 0; i < cameras.length; i++) {
      if (cameras[i].lensDirection == widget.initialDirection) {
        _cameraIndex = i;
      }
    }
    _startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: _controller?.value.isInitialized == true
          ? Container(
              color: Colors.black,
              child: Stack(
                children: <Widget>[
                  Center(child: CameraPreview(_controller!)),
                  if (widget.title != null)
                    Align(
                      alignment: Alignment.centerRight,
                      child: RotatedBox(
                        quarterTurns: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            widget.title!,
                            style: const TextStyle(
                              fontFamily: "Montserrat",
                              fontWeight: FontWeight.w700,
                              fontSize: 16.0,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 5.0,
                                  color: Color.fromARGB(180, 0, 0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Center(
                    child: Container(
                      width: 2.0,
                      height: _screenHeight * 0.8,
                      color: widget.color,
                    ),
                  ),
                ],
              ),
            )
          : Container(),
    );
  }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        zoomLevel = value;
        minZoomLevel = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        maxZoomLevel = value;
      });
      _controller?.lockCaptureOrientation(DeviceOrientation.portraitUp);
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation = InputImageRotationMethods.fromRawValue(camera.sensorOrientation) ??
        InputImageRotation.Rotation_0deg;

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

    final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.onImage(inputImage);
  }
}
