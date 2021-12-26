library barcode_bill_scanner;

import 'package:barcode_bill_scanner/util/bill_util.class.dart';
import 'package:flutter/material.dart';
import 'package:google_barcode_kit/google_barcode_kit.dart';

import 'widgets/bill_scan_camera.widget.dart';

/// Tela onde a câmera faz a leitura do código de barras.
class BarcodeBillScanner extends StatefulWidget {
  const BarcodeBillScanner({
    Key? key,
    this.infoText = 'Utilize a câmera para leitura do boleto bancário',
    required this.onSuccess,
    required this.onCancel,
    this.onError,
    this.onCancelLabel = "Voltar",
    this.color = Colors.cyan,
    this.textColor = const Color(0xffffffff),
    this.convertToFebraban = true,
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
    double _screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        BillScanCameraWidget(
          title: widget.infoText,
          color: widget.color,
          onImage: (inputImage) {
            _processImage(inputImage);
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxHeight: _screenHeight / 2),
            child: RotatedBox(
              quarterTurns: 1,
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: ElevatedButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    widget.onCancelLabel,
                    style: TextStyle(
                      fontFamily: "Montserrat",
                      fontWeight: FontWeight.w700,
                      fontSize: 16.0,
                      color: widget.textColor,
                    ),
                  ),
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color?>(const Color(0xffa3a3a3)),
                    backgroundColor: MaterialStateProperty.all<Color?>(widget.color),
                    minimumSize:
                        MaterialStateProperty.all<Size?>(const Size(double.infinity, 48.0)),
                    elevation: MaterialStateProperty.all<double>(2),
                    shape: MaterialStateProperty.all<OutlinedBorder?>(
                      RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.black, width: 1.0),
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
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
