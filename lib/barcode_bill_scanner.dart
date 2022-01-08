library barcode_bill_scanner;

import 'package:barcode_bill_scanner/util/bill_util.class.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_barcode_kit/google_barcode_kit.dart';

import 'widgets/bill_scan_camera.widget.dart';

/// Widget utilizado para leitura e conversão de código de barras.
///
/// Este widget serve como tela para exibição da câmera que faz a leitura do código de barras.
/// Abaixo pode-se observar um exemplo de uso:
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
    this.infoText = 'Escaneie o código de barras do boleto',
    required this.onSuccess,
    required this.onCancel,
    this.onError,
    this.onCancelLabel = "Voltar",
    this.color = Colors.cyan,
    this.textColor = const Color(0xff696876),
    this.convertToFebraban = true,
    this.backdropColor = const Color(0x99000000),
  }) : super(key: key);

  /// Texto informativo exibido ao topo da tela
  final String infoText;

  /// Função que recebe o código de barras em formato String.
  final Future<dynamic> Function(String value) onSuccess;

  /// Função chamada pelo botão de voltar/cancelar.
  final Function() onCancel;

  /// Texto exibido no botão de voltar/cancelar.
  final String onCancelLabel;

  /// Função chamada quando ocorre um erro ao escanear o código.
  final Function()? onError;

  /// Cor principal do scan, utilizada nos botões, textos e linha de scan.
  final Color color;

  /// Cor do texto. Deve ser constrastante com a [color].
  final Color textColor;

  /// Converte o código de barras de 40 dígitos para o padrão FEBRABAN (47/48 dígitos).
  final bool convertToFebraban;

  /// Cor escura e transparente que cria uma moldura em torno do formato da barra.
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
                  onTap: widget.onCancel,
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        widget.onCancelLabel,
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

  /// Realiza a leitura da imagem [inputImage] para conversão em código.
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
