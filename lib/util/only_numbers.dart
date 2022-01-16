/// Formats a [String] so it has only number characters in it's output.
extension OnlyNumbersExtension on String {
  String formatOnlyNumbers() => replaceAllMapped(
        RegExp(r"([^0-9])", caseSensitive: false),
        (Match m) => "",
      );
}
