import 'package:barcode_bill_scanner/util/bill_util.class.dart';
import 'package:test/test.dart';

void main() {
  const String regularBarcode = "00199883600000010000000003406098001381742417";
  const String concessionaryBarcode = "84650000000356802921000131250349092112195973";

  group("Conversion", () {
    test("should convert a 44-length regular barcode to FEBRABAN format.", () {
      final String converted = BillUtil.getFormattedbarcode(regularBarcode);

      expect(converted, "00190000090340609800813817424172988360000001000");
    });

    test("should convert a 44-length concessionary barcode to FEBRABAN format.", () {
      final String converted = BillUtil.getFormattedbarcode(concessionaryBarcode);

      expect(converted, "846500000001356802921003013125034903921121959735");
    });
  });

  group("Identify type", () {
    test("should identify if the barcode is of regular type.", () {
      bool isConcessionary = BillUtil.isConcessionary(regularBarcode);
      expect(isConcessionary, false);
    });
    test("should identify if the barcode is of type concessionary.", () {
      bool isConcessionary = BillUtil.isConcessionary(concessionaryBarcode);
      expect(isConcessionary, true);
    });
  });
}
