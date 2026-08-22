import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  test('numeric invoice date formatting needs no asynchronous locale symbols', () {
    expect(
      () => DateFormat('dd/MM/yyyy').format(DateTime(2026, 7, 31)),
      returnsNormally,
    );
  });
}
