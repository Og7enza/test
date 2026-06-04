extension FormatToTwoDecimalPlaces on String {
  String toTwoDecimalPlaces() {
    // Try to parse the string as a double
    double? value = double.tryParse(this);

    // If parsing fails, return the original string
    if (value == null) {
      return this;
    }

    // Format the number to two decimal places
    return value.toStringAsFixed(2);
  }
}