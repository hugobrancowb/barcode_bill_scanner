library barcode_bill_scanner;

import 'package:barcode_bill_scanner/util/bill_util.class.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_barcode_kit/google_barcode_kit.dart';

import 'widgets/bill_scan_camera.widget.dart';

/// Widget used to read and convert a barcode.
///
/// It shows a friendly interface guiding the user to scan the barcode using the phone's camera.
/// Este widget serve como tela para exibição da câmera que faz a leitura do código de barras.
///
/// Example:
///
/// ```dart
///  @override
///  Widget build(BuildContext context) {
///    return Stack(
///      alignment: Alignment.center,
///      children: [
///        BarcodeBillScanner(
///          onCancelLabel: "You can set a message to cancel an action",
///          onSuccess: (String value) async {
///            setState(() => barcode = value);
///          },
///          onCancel: () {
///            setState(() => barcode = null);
///          },
///        ),
///        if (barcode != null)
///          Text(
///            barcode!,
///            textAlign: TextAlign.center,
///            style: const TextStyle(
///              fontSize: 20.0,
///              color: Colors.amber,
///            ),
///          ),
///      ],
///    );
///  }
/// ```
class BarcodeBillScanner extends StatefulWidget {
  const BarcodeBillScanner({
    Key? key,
    this.infoText = "Scan the barcode using your camera.",
    required this.onSuccess,
    this.onAction,
    required this.onCancel,
    this.onError,
    this.onActionLabel = "Type barcode",
    this.color = Colors.cyan,
    this.textColor = const Color(0xff696876),
    this.convertToFebraban = true,
    this.backdropColor = const Color(0x99000000),
  }) : super(key: key);

  /// Text shown on top of the screen.
  final String infoText;

  /// Method called after the barcode is successfuly read and converted.
  final Future<dynamic> Function(String value) onSuccess;

  /// Method called by the action button.
  final Function()? onAction;

  /// Method called by the cancel button.
  final Function() onCancel;

  /// Label for the action button.
  final String onActionLabel;

  /// Method called on error while reading the barcode.
  final Function()? onError;

  /// Main color.
  final Color color;

  /// Text color. Must have enough contrast with [color].
  final Color textColor;

  /// If `true` converts the barcode to FEBRABAN format (47/48 characters long).
  final bool convertToFebraban;

  /// Backdrop color used as a frame for reading the barcode.
  final Color backdropColor;

  @override
  _BarcodeMLKitState createState() => _BarcodeMLKitState();
}

class _BarcodeMLKitState extends State<BarcodeBillScanner> {
  BarcodeScanner barcodeScanner = GoogleMlKit.vision.barcodeScanner([
    BarcodeFormat.itf,
    BarcodeFormat.codabar,
  ]);
  bool isBusy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 12.0,
        backgroundColor: Colors.black,
        automaticallyImplyLeading: false,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          systemStatusBarContrastEnforced: true,
        ),
        elevation: 0,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          BillScanCameraWidget(
            onImage: (inputImage) {
              _processImage(inputImage);
            },
          ),
          RotatedBox(
            quarterTurns: 1,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  color: widget.backdropColor,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: widget.onCancel,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(24.0, 16.0, 16.0, 16.0),
                            child: Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          widget.infoText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: "Montserrat",
                            fontWeight: FontWeight.w500,
                            fontSize: 16.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: widget.backdropColor,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    color: widget.backdropColor,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onAction,
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        widget.onActionLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Montserrat",
                          fontWeight: FontWeight.w500,
                          fontSize: 16.0,
                          color: widget.textColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Processes the [inputImage] to extract and format the barcode's numbers.
  Future<void> _processImage(InputImage inputImage) async {
    if (isBusy) return;
    isBusy = true;
    final barcodes = await barcodeScanner.processImage(inputImage);

    if (barcodes.isNotEmpty) {
      try {
        Barcode validBarcode = barcodes.firstWhere((e) => e.value.displayValue?.length == 44);
        String code = widget.convertToFebraban
            ? BillUtil.getFormattedbarcode(validBarcode.value.displayValue!)
            : validBarcode.value.displayValue!;

        widget.onSuccess(code).whenComplete(() => isBusy = false);
      } catch (e) {
        if (widget.onError != null) widget.onError!();
      }
    }

    isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
