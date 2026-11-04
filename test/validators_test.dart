import 'package:cir/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('email', () {
    test('accepts ALU addresses in any case', () {
      expect(Validators.email('a@alueducation.com'), isNull);
      expect(Validators.email('A@ALUSTUDENT.COM'), isNull);
      expect(Validators.email('  b.niyigena@alustudent.com '), isNull);
    });

    test('rejects other domains and look-alikes', () {
      expect(Validators.email('a@gmail.com'), isNotNull);
      expect(Validators.email('a@alueducation.com.evil.io'), isNotNull);
      expect(Validators.email('a@sub.alueducation.com'), isNotNull);
      expect(Validators.email('a@alueducation.org'), isNotNull);
    });

    test('rejects empty and malformed input', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('@alustudent.com'), isNotNull);
      expect(Validators.email('no-at-sign'), isNotNull);
    });
  });

  group('password', () {
    test('needs upper, lower, digit and 8 characters', () {
      expect(Validators.password('Abcdefg1'), isNull);
      expect(Validators.password('abc12345'), isNotNull);
      expect(Validators.password('ABC12345'), isNotNull);
      expect(Validators.password('Abcdefgh'), isNotNull);
      expect(Validators.password('Abc1'), isNotNull);
      expect(Validators.password(''), isNotNull);
    });
  });

  group('name', () {
    test('allows letters, spaces, apostrophes, dots and hyphens', () {
      expect(Validators.name("Jean-Paul O'Neil"), isNull);
      expect(Validators.name('Bonane N.'), isNull);
    });

    test('rejects digits, symbols and too short or long names', () {
      expect(Validators.name('B'), isNotNull);
      expect(Validators.name('John3'), isNotNull);
      expect(Validators.name('<script>'), isNotNull);
      expect(Validators.name('a' * 51), isNotNull);
      expect(Validators.name('  '), isNotNull);
    });
  });

  group('report fields', () {
    test('title length is 5 to 80', () {
      expect(Validators.title('Leak'), isNotNull);
      expect(Validators.title('Water leak'), isNull);
      expect(Validators.title('a' * 81), isNotNull);
    });

    test('description length is 10 to 500', () {
      expect(Validators.description('too short'), isNotNull);
      expect(Validators.description('The tap in block B is broken'), isNull);
      expect(Validators.description('a' * 501), isNotNull);
    });

    test('required rejects blank values', () {
      expect(Validators.required(null, 'Building'), 'Building is required');
      expect(Validators.required(' ', 'Building'), isNotNull);
      expect(Validators.required('Library', 'Building'), isNull);
    });
  });
}
