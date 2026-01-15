import 'package:flutter/material.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/services/exchange_rate_service.dart';

class CurrencySelector extends StatelessWidget {
  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;
  final bool showAllCurrencies;

  const CurrencySelector({
    super.key,
    required this.selectedCurrency,
    required this.onCurrencySelected,
    this.showAllCurrencies = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCurrencyPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textDisabled),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Text(
              ExchangeRateService.getCurrencySymbol(selectedCurrency),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCurrency,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    ExchangeRateService.currencyNames[selectedCurrency] ??
                        selectedCurrency,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _CurrencyPickerContent(
              selectedCurrency: selectedCurrency,
              onCurrencySelected: (currency) {
                onCurrencySelected(currency);
                Navigator.pop(context);
              },
              scrollController: scrollController,
              showAllCurrencies: showAllCurrencies,
            );
          },
        );
      },
    );
  }
}

class _CurrencyPickerContent extends StatefulWidget {
  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;
  final ScrollController scrollController;
  final bool showAllCurrencies;

  const _CurrencyPickerContent({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.scrollController,
    required this.showAllCurrencies,
  });

  @override
  State<_CurrencyPickerContent> createState() => _CurrencyPickerContentState();
}

class _CurrencyPickerContentState extends State<_CurrencyPickerContent> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredCurrencies {
    final currencies = widget.showAllCurrencies
        ? ExchangeRateService.currencyNames.keys.toList()
        : ExchangeRateService.commonCurrencies;

    if (_searchQuery.isEmpty) return currencies;

    return currencies.where((code) {
      final name = ExchangeRateService.currencyNames[code] ?? '';
      return code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Select Currency',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: _filteredCurrencies.length,
            itemBuilder: (context, index) {
              final currency = _filteredCurrencies[index];
              final isSelected = currency == widget.selectedCurrency;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isSelected
                      ? AppColors.primary
                      : AppColors.primaryLight.withOpacity(0.3),
                  child: Text(
                    ExchangeRateService.getCurrencySymbol(currency),
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(currency),
                subtitle: Text(
                  ExchangeRateService.currencyNames[currency] ?? '',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => widget.onCurrencySelected(currency),
              );
            },
          ),
        ),
      ],
    );
  }
}
