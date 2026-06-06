import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/api/converters/datetime_converter.dart';

void main() {
  group('DateTimeUtcConverter', () {
    const converter = DateTimeUtcConverter();

    test(
      'Given DateTimeUtcConverter, When executing, Then fromJson should parse ISO8601 string and convert to local time',
      () {
        const json = '2024-05-10T10:00:00Z';
        final result = converter.fromJson(json);

        expect(result.isUtc, isFalse);
        // Since result is local, we compare with a DateTime created from UTC
        expect(result, DateTime.parse(json).toLocal());
      },
    );

    test('Given DateTimeUtcConverter, When executing, Then toJson should convert DateTime to UTC ISO8601 string', () {
      final date = DateTime(2024, 5, 10, 10, 0, 0); // Local time
      final result = converter.toJson(date);

      expect(result, date.toUtc().toIso8601String());
      expect(result.endsWith('Z') || result.contains('+00:00') || !result.contains('+'), isTrue);
      // standard toIso8601String on UTC usually ends with nothing if no offset is present or Z if specified,
      // but in Dart toUtc().toIso8601String() doesn't always add Z if not careful,
      // actually Dart's toIso8601String() on a UTC DateTime ends with 'Z' if it's indeed UTC.
      expect(result.endsWith('Z'), isTrue);
    });
  });

  group('NullableDateTimeUtcConverter', () {
    const converter = NullableDateTimeUtcConverter();

    test('Given input is null, When calling NullableDateTimeUtcConverter, Then fromJson should return null', () {
      expect(converter.fromJson(null), isNull);
    });

    test('Given NullableDateTimeUtcConverter, When executing, Then fromJson should parse non-null string', () {
      const json = '2024-05-10T10:00:00Z';
      expect(converter.fromJson(json), DateTime.parse(json).toLocal());
    });

    test('Given input is null, When calling NullableDateTimeUtcConverter, Then toJson should return null', () {
      expect(converter.toJson(null), isNull);
    });

    test(
      'Given NullableDateTimeUtcConverter, When executing, Then toJson should convert non-null DateTime to UTC string',
      () {
        final date = DateTime(2024, 5, 10, 10, 0, 0);
        expect(converter.toJson(date), date.toUtc().toIso8601String());
      },
    );
  });

  group('DateOnlyConverter', () {
    const converter = DateOnlyConverter();

    test('Given DateOnlyConverter, When executing, Then fromJson should parse YYYY-MM-DD string', () {
      const json = '2024-05-10';
      final result = converter.fromJson(json);

      expect(result.year, 2024);
      expect(result.month, 5);
      expect(result.day, 10);
    });

    test('Given DateOnlyConverter, When executing, Then toJson should serialize to YYYY-MM-DD string', () {
      final date = DateTime(2024, 5, 10, 15, 30, 0);
      final result = converter.toJson(date);

      expect(result, '2024-05-10');
    });

    test(
      'Given DateOnlyConverter, When executing, Then toJson should handle single digit month and day with padding',
      () {
        final date = DateTime(2024, 1, 5);
        final result = converter.toJson(date);

        expect(result, '2024-01-05');
      },
    );
  });

  group('NullableDateOnlyConverter', () {
    const converter = NullableDateOnlyConverter();

    test('Given input is null, When calling NullableDateOnlyConverter, Then fromJson should return null', () {
      expect(converter.fromJson(null), isNull);
    });

    test('Given NullableDateOnlyConverter, When executing, Then fromJson should parse non-null string', () {
      const json = '2024-05-10';
      final result = converter.fromJson(json);
      expect(result?.year, 2024);
      expect(result?.day, 10);
    });

    test('Given input is null, When calling NullableDateOnlyConverter, Then toJson should return null', () {
      expect(converter.toJson(null), isNull);
    });

    test('Given NullableDateOnlyConverter, When executing, Then toJson should serialize non-null to YYYY-MM-DD', () {
      final date = DateTime(2024, 5, 10);
      expect(converter.toJson(date), '2024-05-10');
    });
  });
}
