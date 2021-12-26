/// Extrai apenas os números de uma string.
extension OnlyNumbersExtension on String {
  String formatOnlyNumbers() {
    return this.replaceAllMapped(
      RegExp(r"([^0-9])", caseSensitive: false),
      (Match m) => "",
    );
  }
}
