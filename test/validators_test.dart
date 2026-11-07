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

  group('field limits and messages', () {
    test('email says what is wrong', () {
      expect(Validators.email('nope'), contains('@'));
      expect(Validators.email('a@b@alustudent.com'), contains('one @'));
      expect(Validators.email('${'a' * 65}@alustudent.com'), contains('64'));
      expect(Validators.email('a b@alustudent.com'), contains('letters'));
      expect(Validators.email('.a@alustudent.com'), contains('letters'));
      expect(Validators.email('a..b@alustudent.com'), contains('letters'));
    });

    test('password tells which rule is missing first', () {
      expect(Validators.password('Abc1'), 'Use at least 8 characters');
      expect(Validators.password('abcdefg1'), 'Add an uppercase letter');
      expect(Validators.password('ABCDEFG1'), 'Add a lowercase letter');
      expect(Validators.password('Abcdefgh'), 'Add a number');
      expect(Validators.password('Abc defg1'), 'Password can’t contain spaces');
      expect(Validators.password('A1b${'c' * 70}'), contains('64'));
    });

    test('password score counts the rules met', () {
      expect(Validators.passwordScore(''), 0);
      expect(Validators.passwordScore('abc'), 1);
      expect(Validators.passwordScore('Abcdefg1'), 4);
    });

    test('confirmation must match', () {
      expect(Validators.confirmPassword('', 'Abcdefg1'), isNotNull);
      expect(Validators.confirmPassword('Abcdefg2', 'Abcdefg1'), isNotNull);
      expect(Validators.confirmPassword('Abcdefg1', 'Abcdefg1'), isNull);
    });

    test('names accept accented letters but not digits or symbols', () {
      expect(Validators.name('Zoë Müller'), isNull);
      expect(Validators.name('Chloé D’Souza'), isNull);
      expect(Validators.name('J'), 'Enter at least 2 letters');
      expect(Validators.name('Ann3'), contains('letters'));
    });

    test('report text rejects markup characters', () {
      expect(Validators.title('Leak <script> now'), isNotNull);
      expect(Validators.description('The pipe {leaks} badly today'), isNotNull);
      expect(Validators.title('Leak (urgent) at Library!'), isNull);
    });

    test('a rejection needs a reason', () {
      expect(Validators.updateNote('', mandatory: true), isNotNull);
      expect(Validators.updateNote('', mandatory: false), isNull);
      expect(Validators.updateNote('x' * 201, mandatory: false), isNotNull);
      expect(Validators.updateNote('Duplicate of #4', mandatory: true), isNull);
    });

    test('facility names and areas', () {
      expect(Validators.facilityName('Main Library (West)'), isNull);
      expect(Validators.facilityName('A'), isNotNull);
      expect(Validators.facilityName('Lab <1>'), isNotNull);
      expect(Validators.facilityName('x' * 41), isNotNull);
      expect(Validators.areas('Study area\nGroup rooms'), isNull);
      expect(Validators.areas('x' * 41), isNotNull);
      expect(Validators.areas(List.filled(21, 'Room').join('\n')), isNotNull);
    });
  });
}
