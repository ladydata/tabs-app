import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tabs/services/exchange_rate_service.dart';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

@GenerateNiceMocks([MockSpec<http.Client>()])
import 'exchange_rate_test.mocks.dart';

void main() {
  group('ExchangeRateService', () {
    late ExchangeRateService service;
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
      service = ExchangeRateService(
        client: mockClient,
        firestore: FakeFirebaseFirestore(),
      );
    });

    test('getExchangeRate success', () async {
      // Setup mock response
      const jsonResponse = '''
      {
        "result": "success",
        "conversion_rates": {
          "EUR": 0.85
        }
      }
      ''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(jsonResponse, 200),
      );

      final rate = await service.getExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        date: DateTime.now(),
      );

      expect(rate, 0.85);
    });

    test('getExchangeRate same currency returns 1.0', () async {
      final rate = await service.getExchangeRate(
        fromCurrency: 'USD',
        toCurrency: 'USD',
        date: DateTime.now(),
      );

      expect(rate, 1.0);
    });

    test('convert works correctly', () async {
      // Setup mock response
      const jsonResponse = '''
      {
        "result": "success",
        "conversion_rates": {
          "JPY": 110.0
        }
      }
      ''';

      when(mockClient.get(any)).thenAnswer(
        (_) async => http.Response(jsonResponse, 200),
      );

      final converted = await service.convert(
        amount: 100,
        fromCurrency: 'USD',
        toCurrency: 'JPY',
        date: DateTime.now(),
      );

      expect(converted, 11000.0);
    });
  });
}
