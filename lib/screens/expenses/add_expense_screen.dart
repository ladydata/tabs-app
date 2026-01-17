import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/providers/expenses_provider.dart';
import 'package:tabs/services/exchange_rate_service.dart';
import 'package:tabs/widgets/common/loading_widget.dart';
import 'package:tabs/widgets/common/currency_selector.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? expenseId; // For editing

  const AddExpenseScreen({
    super.key,
    required this.groupId,
    this.expenseId,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedCurrency = 'USD';
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _selectedPayers = {};
  Map<String, TextEditingController> _payerAmountControllers = {};
  SplitType _splitType = SplitType.equal;
  Map<String, bool> _selectedMembers = {};
  Map<String, TextEditingController> _splitControllers = {};

  bool _isLoading = false;
  double? _exchangeRate;
  double? _convertedAmount;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    for (final controller in _splitControllers.values) {
      controller.dispose();
    }
    for (final controller in _payerAmountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseId != null ? 'Edit Expense' : 'Add Expense'),
      ),
      body: groupAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Group not found'));
          }
          return _buildForm(context, group);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, ExpenseGroup group) {
    // Initialize state based on group
    if (_selectedPayers.isEmpty) {
      final currentUser = ref.read(currentUserProvider);
      _selectedCurrency = group.currency;

      // Initialize payers (default to current user)
      for (final memberId in group.memberIds) {
        _selectedPayers[memberId] = memberId == currentUser?.uid;
        _payerAmountControllers[memberId] = TextEditingController();
      }

      // Initialize selected members for splits
      for (final memberId in group.memberIds) {
        _selectedMembers[memberId] = true;
        _splitControllers[memberId] = TextEditingController();
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Amount and Currency
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${ExchangeRateService.getCurrencySymbol(_selectedCurrency)} ',
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                    onChanged: (_) => _updateConversion(group),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Currency'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectCurrency(group),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.textDisabled),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selectedCurrency,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Show conversion if different currency
            if (_selectedCurrency != group.currency && _convertedAmount != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.currency_exchange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '= ${ExchangeRateService.formatAmount(_convertedAmount!, group.currency)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      'Rate: ${_exchangeRate?.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Title
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What was this expense for?',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Date
            InkWell(
              onTap: () => _selectDate(group),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Add any additional details...',
                prefixIcon: Icon(Icons.notes_outlined),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Paid by
            Row(
              children: [
                Text(
                  'Paid by',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (_selectedPayerCount > 1)
                  TextButton.icon(
                    onPressed: () => _splitPayersEvenly(group),
                    icon: const Icon(Icons.drag_handle, size: 18),
                    label: const Text('Split evenly'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: group.members.entries.map((entry) {
                final isSelected = _selectedPayers[entry.key] ?? false;
                return FilterChip(
                  label: Text(entry.value.displayName),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedPayers[entry.key] = selected;
                      if (!selected) {
                        _payerAmountControllers[entry.key]?.clear();
                      } else if (_selectedPayerCount == 1) {
                        // Auto-fill amount for single payer
                        _payerAmountControllers[entry.key]?.text = _amountController.text;
                      }
                    });
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                );
              }).toList(),
            ),

            // Payer amounts (shown when multiple payers or single payer selected)
            if (_selectedPayerCount > 0) ...[
              const SizedBox(height: 16),
              ...group.members.entries
                  .where((e) => _selectedPayers[e.key] ?? false)
                  .map((entry) => _buildPayerAmountInput(entry.key, entry.value.displayName, group)),
              if (_selectedPayerCount > 1) ...[
                const SizedBox(height: 8),
                _buildPayerTotalValidation(group),
              ],
            ],

            const SizedBox(height: 24),

            // Split type
            Text(
              'Split',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<SplitType>(
              segments: const [
                ButtonSegment(
                  value: SplitType.equal,
                  label: Text('Equally'),
                  icon: Icon(Icons.drag_handle),
                ),
                ButtonSegment(
                  value: SplitType.percentage,
                  label: Text('By %'),
                  icon: Icon(Icons.percent),
                ),
                ButtonSegment(
                  value: SplitType.exact,
                  label: Text('Exact'),
                  icon: Icon(Icons.attach_money),
                ),
              ],
              selected: {_splitType},
              onSelectionChanged: (selection) {
                setState(() => _splitType = selection.first);
              },
            ),

            const SizedBox(height: 16),

            // Split among
            Text(
              'Split among',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 8),
            ...group.members.entries.map((entry) {
              final isSelected = _selectedMembers[entry.key] ?? false;
              return CheckboxListTile(
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    _selectedMembers[entry.key] = value ?? false;
                  });
                },
                title: Text(entry.value.displayName),
                subtitle: _splitType != SplitType.equal
                    ? _buildSplitInput(entry.key, group)
                    : null,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),

            const SizedBox(height: 32),

            // Submit button
            ElevatedButton(
              onPressed: _isLoading ? null : () => _saveExpense(group),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.expenseId != null ? 'Save Changes' : 'Add Expense'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitInput(String memberId, ExpenseGroup group) {
    if (!(_selectedMembers[memberId] ?? false)) {
      return const SizedBox.shrink();
    }

    final controller = _splitControllers[memberId]!;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: 100,
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            isDense: true,
            suffixText: _splitType == SplitType.percentage ? '%' : group.currency,
          ),
        ),
      ),
    );
  }

  int get _selectedPayerCount =>
      _selectedPayers.values.where((v) => v).length;

  void _splitPayersEvenly(ExpenseGroup group) {
    final amountText = _amountController.text;
    if (amountText.isEmpty) return;

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    final selectedPayerIds = _selectedPayers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedPayerIds.isEmpty) return;

    final amountPerPayer = amount / selectedPayerIds.length;
    for (final payerId in selectedPayerIds) {
      _payerAmountControllers[payerId]?.text = amountPerPayer.toStringAsFixed(2);
    }
    setState(() {});
  }

  Widget _buildPayerAmountInput(String memberId, String displayName, ExpenseGroup group) {
    final controller = _payerAmountControllers[memberId]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: AppColors.primaryDark, fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(displayName),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                isDense: true,
                prefixText: '${ExchangeRateService.getCurrencySymbol(_selectedCurrency)} ',
                hintText: '0.00',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayerTotalValidation(ExpenseGroup group) {
    final amountText = _amountController.text;
    final totalAmount = double.tryParse(amountText) ?? 0;

    double payerTotal = 0;
    for (final entry in _selectedPayers.entries) {
      if (entry.value) {
        final payerAmount = double.tryParse(_payerAmountControllers[entry.key]?.text ?? '') ?? 0;
        payerTotal += payerAmount;
      }
    }

    final difference = totalAmount - payerTotal;
    final isValid = difference.abs() < 0.01;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid
            ? AppColors.success.withOpacity(0.1)
            : AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            size: 20,
            color: isValid ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isValid
                  ? 'Payer amounts match total'
                  : 'Payer total: ${ExchangeRateService.formatAmount(payerTotal, _selectedCurrency)} '
                      '(${difference > 0 ? "missing" : "over by"} ${ExchangeRateService.formatAmount(difference.abs(), _selectedCurrency)})',
              style: TextStyle(
                color: isValid ? AppColors.success : AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectCurrency(ExpenseGroup group) {
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
            return _CurrencyPicker(
              selectedCurrency: _selectedCurrency,
              onCurrencySelected: (currency) {
                setState(() => _selectedCurrency = currency);
                Navigator.pop(context);
                _updateConversion(group);
              },
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }

  Future<void> _selectDate(ExpenseGroup group) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
      _updateConversion(group);
    }
  }

  Future<void> _updateConversion(ExpenseGroup group) async {
    if (_selectedCurrency == group.currency) {
      setState(() {
        _exchangeRate = 1.0;
        _convertedAmount = null;
      });
      return;
    }

    final amountText = _amountController.text;
    if (amountText.isEmpty) {
      setState(() {
        _exchangeRate = null;
        _convertedAmount = null;
      });
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    try {
      final exchangeRateService = ref.read(exchangeRateServiceProvider);
      final rate = await exchangeRateService.getExchangeRate(
        fromCurrency: _selectedCurrency,
        toCurrency: group.currency,
        date: _selectedDate,
      );

      setState(() {
        _exchangeRate = rate;
        _convertedAmount = amount * rate;
      });
    } catch (e) {
      // Handle error silently, will show when saving
    }
  }

  Future<void> _saveExpense(ExpenseGroup group) async {
    if (!_formKey.currentState!.validate()) return;

    final selectedPayerIds = _selectedPayers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedPayerIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one payer')),
      );
      return;
    }

    final selectedMemberIds = _selectedMembers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one person to split with')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      // Build payers map
      final payers = <String, double>{};
      double payerTotal = 0;

      for (final payerId in selectedPayerIds) {
        final payerAmountText = _payerAmountControllers[payerId]?.text ?? '';
        final payerAmount = double.tryParse(payerAmountText) ?? 0;
        if (payerAmount <= 0) {
          throw Exception('Each payer must have an amount greater than 0');
        }
        payers[payerId] = payerAmount;
        payerTotal += payerAmount;
      }

      // Validate payer amounts equal expense amount
      if ((payerTotal - amount).abs() > 0.01) {
        throw Exception('Payer amounts must equal the expense total');
      }

      // Build splits based on split type
      final splits = <String, ExpenseSplit>{};

      switch (_splitType) {
        case SplitType.equal:
          final splitAmount = amount / selectedMemberIds.length;
          for (final memberId in selectedMemberIds) {
            splits[memberId] = ExpenseSplit(
              userId: memberId,
              amount: splitAmount,
              type: SplitType.equal,
            );
          }
          break;

        case SplitType.percentage:
          double totalPercentage = 0;
          for (final memberId in selectedMemberIds) {
            final percentage = double.tryParse(_splitControllers[memberId]?.text ?? '') ?? 0;
            totalPercentage += percentage;
            splits[memberId] = ExpenseSplit(
              userId: memberId,
              amount: amount * percentage / 100,
              type: SplitType.percentage,
              percentage: percentage,
            );
          }
          if ((totalPercentage - 100).abs() > 0.01) {
            throw Exception('Percentages must add up to 100%');
          }
          break;

        case SplitType.exact:
          double totalSplit = 0;
          for (final memberId in selectedMemberIds) {
            final splitAmount = double.tryParse(_splitControllers[memberId]?.text ?? '') ?? 0;
            totalSplit += splitAmount;
            splits[memberId] = ExpenseSplit(
              userId: memberId,
              amount: splitAmount,
              type: SplitType.exact,
            );
          }
          if ((totalSplit - amount).abs() > 0.01) {
            throw Exception('Split amounts must equal the total');
          }
          break;
      }

      await ref.read(expensesNotifierProvider.notifier).createExpense(
            groupId: widget.groupId,
            title: _titleController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            amount: amount,
            currency: _selectedCurrency,
            date: _selectedDate,
            payers: payers,
            splits: splits,
          );

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

class _CurrencyPicker extends StatefulWidget {
  final String selectedCurrency;
  final ValueChanged<String> onCurrencySelected;
  final ScrollController scrollController;

  const _CurrencyPicker({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.scrollController,
  });

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  String _searchQuery = '';

  List<String> get _filteredCurrencies {
    final currencies = ExchangeRateService.currencyNames.keys.toList();
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
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search currencies...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
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
                    ),
                  ),
                ),
                title: Text(currency),
                subtitle: Text(ExchangeRateService.currencyNames[currency] ?? ''),
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
