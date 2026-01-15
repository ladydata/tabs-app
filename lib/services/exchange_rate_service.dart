import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ExchangeRateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TODO: Replace with your API key from https://www.exchangerate-api.com/
  static const String _apiKey = 'YOUR_API_KEY';
  static const String _baseUrl = 'https://v6.exchangerate-api.com/v6';

  // Common currencies for quick selection
  static const List<String> commonCurrencies = [
    'USD', 'EUR', 'GBP', 'JPY', 'CAD', 'AUD', 'CHF', 'CNY', 'INR', 'MXN',
    'BRL', 'KRW', 'SGD', 'HKD', 'NOK', 'SEK', 'DKK', 'NZD', 'ZAR', 'RUB',
  ];

  // All supported currencies with names
  static const Map<String, String> currencyNames = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CAD': 'Canadian Dollar',
    'AUD': 'Australian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Chinese Yuan',
    'INR': 'Indian Rupee',
    'MXN': 'Mexican Peso',
    'BRL': 'Brazilian Real',
    'KRW': 'South Korean Won',
    'SGD': 'Singapore Dollar',
    'HKD': 'Hong Kong Dollar',
    'NOK': 'Norwegian Krone',
    'SEK': 'Swedish Krona',
    'DKK': 'Danish Krone',
    'NZD': 'New Zealand Dollar',
    'ZAR': 'South African Rand',
    'RUB': 'Russian Ruble',
    'PLN': 'Polish Zloty',
    'THB': 'Thai Baht',
    'IDR': 'Indonesian Rupiah',
    'MYR': 'Malaysian Ringgit',
    'PHP': 'Philippine Peso',
    'CZK': 'Czech Koruna',
    'ILS': 'Israeli Shekel',
    'CLP': 'Chilean Peso',
    'PKR': 'Pakistani Rupee',
    'COP': 'Colombian Peso',
    'SAR': 'Saudi Riyal',
    'AED': 'UAE Dirham',
    'TWD': 'Taiwan Dollar',
    'ARS': 'Argentine Peso',
    'VND': 'Vietnamese Dong',
    'EGP': 'Egyptian Pound',
    'TRY': 'Turkish Lira',
    'NGN': 'Nigerian Naira',
    'BDT': 'Bangladeshi Taka',
    'UAH': 'Ukrainian Hryvnia',
  };

  /// Get exchange rate between two currencies for a specific date
  Future<double> getExchangeRate({
    required String fromCurrency,
    required String toCurrency,
    required DateTime date,
  }) async {
    // If same currency, rate is 1
    if (fromCurrency == toCurrency) return 1.0;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Try to get from cache first
    final cachedRate = await _getCachedRate(dateStr, fromCurrency, toCurrency);
    if (cachedRate != null) return cachedRate;

    // Fetch from API
    final rates = await _fetchRates(fromCurrency, date);
    if (rates == null) {
      throw Exception('Failed to fetch exchange rates');
    }

    // Cache the rates
    await _cacheRates(dateStr, fromCurrency, rates);

    final rate = rates[toCurrency];
    if (rate == null) {
      throw Exception('Currency $toCurrency not found');
    }

    return rate;
  }

  /// Convert amount from one currency to another
  Future<double> convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
    required DateTime date,
  }) async {
    final rate = await getExchangeRate(
      fromCurrency: fromCurrency,
      toCurrency: toCurrency,
      date: date,
    );
    return amount * rate;
  }

  /// Get cached exchange rate
  Future<double?> _getCachedRate(
    String date,
    String fromCurrency,
    String toCurrency,
  ) async {
    try {
      final doc = await _firestore
          .collection('exchangeRates')
          .doc('$date-$fromCurrency')
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final rates = data['rates'] as Map<String, dynamic>?;
      if (rates == null) return null;

      final rate = rates[toCurrency];
      return rate?.toDouble();
    } catch (e) {
      return null;
    }
  }

  /// Cache exchange rates
  Future<void> _cacheRates(
    String date,
    String baseCurrency,
    Map<String, double> rates,
  ) async {
    try {
      await _firestore
          .collection('exchangeRates')
          .doc('$date-$baseCurrency')
          .set({
        'date': date,
        'base': baseCurrency,
        'rates': rates,
        'fetchedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Ignore cache errors
    }
  }

  /// Fetch rates from API
  Future<Map<String, double>?> _fetchRates(
    String baseCurrency,
    DateTime date,
  ) async {
    try {
      // Check if date is today or in the past
      final today = DateTime.now();
      final isHistorical = date.isBefore(DateTime(today.year, today.month, today.day));

      String url;
      if (isHistorical) {
        // Use historical endpoint
        final year = date.year;
        final month = date.month;
        final day = date.day;
        url = '$_baseUrl/$_apiKey/history/$baseCurrency/$year/$month/$day';
      } else {
        // Use latest endpoint
        url = '$_baseUrl/$_apiKey/latest/$baseCurrency';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);
      if (data['result'] != 'success') {
        return null;
      }

      final conversionRates = data['conversion_rates'] as Map<String, dynamic>;
      return conversionRates.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      return null;
    }
  }

  /// Get currency symbol
  static String getCurrencySymbol(String currencyCode) {
    const symbols = {
      'USD': '\$',
      'EUR': '\u20AC',
      'GBP': '\u00A3',
      'JPY': '\u00A5',
      'CNY': '\u00A5',
      'INR': '\u20B9',
      'KRW': '\u20A9',
      'RUB': '\u20BD',
      'BRL': 'R\$',
      'CHF': 'CHF',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'MXN': 'MX\$',
      'SGD': 'S\$',
      'HKD': 'HK\$',
      'NOK': 'kr',
      'SEK': 'kr',
      'DKK': 'kr',
      'NZD': 'NZ\$',
      'ZAR': 'R',
      'PLN': 'z\u0142',
      'THB': '\u0E3F',
      'ILS': '\u20AA',
      'TRY': '\u20BA',
      'PHP': '\u20B1',
      'CZK': 'K\u010D',
      'AED': 'AED',
      'SAR': 'SAR',
      'TWD': 'NT\$',
    };
    return symbols[currencyCode] ?? currencyCode;
  }

  /// Format amount with currency
  static String formatAmount(double amount, String currencyCode) {
    final formatter = NumberFormat.currency(
      symbol: getCurrencySymbol(currencyCode),
      decimalDigits: currencyCode == 'JPY' || currencyCode == 'KRW' ? 0 : 2,
    );
    return formatter.format(amount);
  }
}
