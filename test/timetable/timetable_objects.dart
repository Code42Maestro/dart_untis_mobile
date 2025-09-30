import 'package:dart_untis_mobile/dart_untis_mobile.dart';
import 'package:test/test.dart';

void main() {
  test('test UntisPeriodState parsing', () {
    expect(UntisPeriodState.parse('regular'), UntisPeriodState.regular);
    expect(UntisPeriodState.parse('irregular'), UntisPeriodState.irregular);
    expect(UntisPeriodState.parse('cancelled'), UntisPeriodState.cancelled);
    expect(UntisPeriodState.parse('unknown'), UntisPeriodState.regular);
  });
}
