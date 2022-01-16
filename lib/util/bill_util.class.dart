import 'package:barcode_bill_scanner/util/only_numbers.dart';

/// Utilitary class used to convert barcode to FEBRABAN format.
///
/// Based on [boleto-utils](https://github.dev/hfsnetbr/boleto-utils) algorithm as well as the
/// FEBRABAN rules as described by [IBBA](https://www.bb.com.br/docs/pub/emp/empl/dwn/Doc5175Bloqueto.pdf).
class BillUtil {
  /// Given a 44 characters long [code], converts and returns a 48 characters long code in FEBRABAN
  /// format.
  static String getFormattedbarcode(String code) {
    code = code.formatOnlyNumbers();
    assert(code.length == 44, "Barcode must be 44 characters long.");

    return isConcessionary(code) ? _buildConcessionaryBarcode(code) : _buildBankBarcode(code);
  }

  /// Converts a regular type barcode to the FEBRABAN format.
  ///
  /// Example:
  /// the barcode input `00199883600000010000000003406098001381742417`
  /// should return `00190000090340609800813817424172988360000001000`.
  static String _buildBankBarcode(String rawCode) {
    String newCode = rawCode.substring(0, 4) +
        rawCode.substring(19) +
        rawCode.substring(4, 5) +
        rawCode.substring(5, 19);

    String block1 = newCode.substring(0, 9) + _mod10(newCode.substring(0, 9));
    String block2 = newCode.substring(9, 19) + _mod10(newCode.substring(9, 19));
    String block3 = newCode.substring(19, 29) + _mod10(newCode.substring(19, 29));
    String block4 = newCode.substring(29);

    return block1 + block2 + block3 + block4;
  }

  /// Converts a concessionary type barcode to the FEBRABAN format.
  ///
  /// Example:
  /// the barcode input `84650000000356802921000131250349092112195973`
  /// should return `846500000001356802921003013125034903921121959735`.
  static String _buildConcessionaryBarcode(String rawCode) {
    String Function(String s) mod = _modRef(rawCode);

    String block1 = rawCode.substring(0, 11) + mod(rawCode.substring(0, 11));
    String block2 = rawCode.substring(11, 22) + mod(rawCode.substring(11, 22));
    String block3 = rawCode.substring(22, 33) + mod(rawCode.substring(22, 33));
    String block4 = rawCode.substring(33) + mod(rawCode.substring(33));

    return block1 + block2 + block3 + block4;
  }

  /// Returns a method used to calculate the modulus based on the reference identifier.
  static String Function(String v) _modRef(String code) {
    String char = code.substring(2, 3);
    if (char == '6' || char == '7') return _mod10;
    return _mod11;
  }

  /// Calculate the type 10 modulus.
  static String _mod10(String code) {
    int factor = 2;
    int sum = code.split("").reversed.map((s) {
      int num = int.parse(s);
      final int digit = num * factor;
      factor = factor == 2 ? 1 : 2;
      return _minimizeNumber(digit);
    }).reduce((t, e) => t + e);

    final int mod = 10 - int.parse(sum.toString().split("").toList().last);
    return (mod == 10 ? 0 : mod).toString();
  }

  /// Calculate the type 11 modulus.
  static String _mod11(String code) {
    const int factorMax = 9;
    int factor = 2;

    final int sum = code.split("").reversed.map((s) {
      int num = int.parse(s);
      final int digit = num * factor;
      factor = factor >= factorMax ? 2 : (factor + 1);
      return digit;
    }).reduce((t, e) => t + e);

    final int mod = sum % 11;
    return ((mod <= 1) ? 0 : (11 - mod)).toString();
  }

  /// Returns `true` if the barcode is of type concessionary; returns `false` for regular barcodes.
  static bool isConcessionary(String barcode) => barcode.substring(0, 1) == '8';

  /// Recursive method that reduces the input [num] until it's only one character long.
  static int _minimizeNumber(int sum) {
    if (sum <= 9) return sum;
    int result = sum.toString().split("").map((s) => int.parse(s)).reduce((a, b) => a + b);
    return result <= 9 ? result : _minimizeNumber(sum);
  }
}
