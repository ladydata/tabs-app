import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tabs/config/categories.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/providers/auth_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/providers/expenses_provider.dart';
import 'package:tabs/services/exchange_rate_service.dart';
import 'package:tabs/widgets/common/loading_widget.dart';
import 'package:tabs/widgets/common/currency_selector.dart';
import 'package:tabs/widgets/expense/payer_selector_modal.dart';
import 'package:tabs/widgets/expense/split_selector_modal.dart';
import 'package:tabs/l10n/app_localizations.dart';

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
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  Map<String, bool> _selectedPayers = {};
  Map<String, TextEditingController> _payerAmountControllers = {};
  SplitType _splitType = SplitType.equal;
  Map<String, bool> _selectedMembers = {};
  Map<String, TextEditingController> _splitControllers = {};

  bool _isLoading = false;
  double? _exchangeRate;
  double? _convertedAmount;

  bool _isDataLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseId != null) {
      // Defer loading until after build to access ref
      Future.microtask(() => _loadExpenseData());
    } else {
      _isDataLoaded = true;
    }
  }

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
        title: Text(widget.expenseId != null 
            ? AppLocalizations.of(context)!.editExpense 
            : AppLocalizations.of(context)!.addExpense),
      ),
      body: groupAsync.when(
        loading: () => const LoadingWidget(),
        error: (error, _) => Center(child: Text('${AppLocalizations.of(context)!.errorGeneric}: $error')),
        data: (group) {
          if (group == null) {
            return Center(child: Text(AppLocalizations.of(context)!.errorGeneric));
          }
          if (!_isDataLoaded) {
             return const LoadingWidget();
          }
          return _buildForm(context, group);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, ExpenseGroup group) {
    if (_selectedPayers.isEmpty) {
      final currentUser = ref.read(currentUserProvider);
      _selectedCurrency = group.currency;

      // Initialize payers (default to current user)
      if (widget.expenseId == null) {
        for (final memberId in group.memberIds) {
          _selectedPayers[memberId] = memberId == currentUser?.uid;
          _payerAmountControllers[memberId] = TextEditingController();
        }
      } else {
        for (final memberId in group.memberIds) {
           if (!_payerAmountControllers.containsKey(memberId)) {
             _payerAmountControllers[memberId] = TextEditingController();
           }
        }
      }

      // Initialize selected members for splits
      if (widget.expenseId == null) {
        for (final memberId in group.memberIds) {
          _selectedMembers[memberId] = true;
          _splitControllers[memberId] = TextEditingController();
        }
      } else {
        for (final memberId in group.memberIds) {
           if (!_splitControllers.containsKey(memberId)) {
             _splitControllers[memberId] = TextEditingController();
           }
        }
      }
    }

    final payerCount = _selectedPayers.values.where((v) => v).length;
    final primaryPayerId = _selectedPayers.entries
        .firstWhere((e) => e.value, orElse: () => _selectedPayers.entries.first)
        .key;
    final primaryPayerName = payerCount > 1 
        ? '$payerCount ${AppLocalizations.of(context)!.paidBy}' // Slightly awkward but close enough for now
        : (group.members[primaryPayerId]?.displayName ?? 'Unknown');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category Selector (Top Center)
            Center(
              child: GestureDetector(
                onTap: () => _showCategorySelector(context),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedCategory != null 
                            ? Categories.getById(_selectedCategory).color.withOpacity(0.1)
                            : AppColors.background,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.textDisabled),
                      ),
                      child: Icon(
                        _selectedCategory != null 
                            ? Categories.getById(_selectedCategory).icon 
                            : Icons.category_outlined,
                        size: 32,
                        color: _selectedCategory != null 
                            ? Categories.getById(_selectedCategory).color 
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedCategory != null 
                          ? Categories.getById(_selectedCategory).name 
                          : AppLocalizations.of(context)!.selectCategory,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),

            // Title Input
            TextFormField(
              controller: _titleController,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.description,
                border: InputBorder.none,
                hintStyle: const TextStyle(fontSize: 18),
              ),
              style: const TextStyle(fontSize: 18),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.errorRequired;
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Amount Input (Large)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                InkWell(
                  onTap: () => _selectCurrency(group),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ExchangeRateService.getCurrencySymbol(_selectedCurrency),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 24),
                      ],
                    ),
                  ),
                ),
                IntrinsicWidth(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    validator: (value) {
                      if (value == null || value.isEmpty || (double.tryParse(value) ?? 0) <= 0) {
                        return AppLocalizations.of(context)!.invalidAmount;
                      }
                      return null;
                    },
                    onChanged: (_) => _updateConversion(group),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Sentence-style Interaction
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('${AppLocalizations.of(context)!.paidBy} '),
                  InkWell(
                    onTap: () => _showPayerSelector(context, group),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        primaryPayerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  Text(' ${AppLocalizations.of(context)!.split} '),
                  InkWell(
                    onTap: () => _showSplitSelector(context, group),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        _splitType == SplitType.equal 
                          ? AppLocalizations.of(context)!.equally.toLowerCase() 
                          : AppLocalizations.of(context)!.unequally,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const Text('.'),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Date & Notes
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(group),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.textDisabled),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                     onTap: () {
                         // Focus notes field or show modal
                     },
                     child: TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.notes,
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                        prefixIcon: const Icon(Icons.notes),
                        isDense: true,
                      ),
                     ),
                  )
                ),
              ],
            ),

             const SizedBox(height: 32),
             
             ElevatedButton(
                onPressed: _isLoading ? null : () => _saveExpense(group),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppLocalizations.of(context)!.save),
             ),
          ],
        ),
      ),
    );
  }

  void _showCategorySelector(BuildContext context) {
     // Reuse existing dropdown items but in a better modal or simple dialog
     showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
             Text(AppLocalizations.of(context)!.selectCategory, style: Theme.of(context).textTheme.titleLarge, textAlign: TextAlign.center),
             const SizedBox(height: 16),
             ...Categories.defaults.map((c) => ListTile(
               leading: Icon(c.icon, color: c.color),
               title: Text(c.name),
               onTap: () {
                 setState(() => _selectedCategory = c.id);
                 Navigator.pop(context);
               },
             )),
          ],
        );
      }
     );
  }

  void _showPayerSelector(BuildContext context, ExpenseGroup group) {
    // Only support single payer UI-selection for simplicity in "Paid by X" text, 
    // but underlying logic supports multi-payer if we wanted to build a complex modal.
    // For now, let's assume single payer selection or "Multiple" handled elsewhere.
    
    // We'll reset to single payer if they select someone here.
    final currentPayer = _selectedPayers.entries.firstWhere((e) => e.value, orElse: () => _selectedPayers.entries.first).key;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PayerSelectorModal(
        group: group,
        selectedPayerId: currentPayer,
        onPayerSelected: (payerId) {
          setState(() {
            _selectedPayers.clear();
            _selectedPayers[payerId] = true;
            // Also update amount controller for this payer? 
            // The robust way is to just clear others.
            // _payerAmountControllers logic happens in _saveExpense based on ratio.
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showSplitSelector(BuildContext context, ExpenseGroup group) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SplitSelectorModal(
        group: group,
        amount: double.tryParse(_amountController.text) ?? 0,
        currency: _selectedCurrency,
        selectedMembers: _selectedMembers,
        splitControllers: _splitControllers,
        initialSplitType: _splitType,
        onSplitChanged: (type, selectedMembers) {
          setState(() {
             _splitType = type;
             _selectedMembers = selectedMembers;
          });
        },
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
        SnackBar(content: Text(AppLocalizations.of(context)!.errorRequired)),
      );
      return;
    }

    final selectedMemberIds = _selectedMembers.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedMemberIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.errorRequired)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);

      // Build payers map
      final payers = <String, double>{};
      double payerTotal = 0;

      if (selectedPayerIds.length == 1) {
        // Single payer: automatically assign full amount
        final payerId = selectedPayerIds.first;
        payers[payerId] = amount;
        payerTotal = amount;
      } else {
        // Multiple payers: read from controllers
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

      if (widget.expenseId != null) {
        await ref.read(expensesNotifierProvider.notifier).updateExpense(
              groupId: widget.groupId,
              expenseId: widget.expenseId!,
              title: _titleController.text.trim(),
              category: _selectedCategory,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              amount: amount,
              currency: _selectedCurrency,
              date: _selectedDate,
              payers: payers,
              splits: splits,
            );
      } else {
        await ref.read(expensesNotifierProvider.notifier).createExpense(
              groupId: widget.groupId,
              title: _titleController.text.trim(),
              category: _selectedCategory,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              amount: amount,
              currency: _selectedCurrency,
              date: _selectedDate,
              payers: payers,
              splits: splits,
            );
      }

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

  Future<void> _loadExpenseData() async {
    try {
      setState(() => _isLoading = true);
      
      final expense = await ref.read(
        expenseProvider((groupId: widget.groupId, expenseId: widget.expenseId!)).future,
      );

      if (expense == null) throw Exception('Expense not found');

      if (!mounted) return;

      setState(() {
        _titleController.text = expense.title;
        _amountController.text = expense.amount.toString(); // Use original amount
        _notesController.text = expense.notes ?? '';
        _selectedCategory = expense.category;
        _selectedCurrency = expense.currency;
        _selectedDate = expense.date;
        _exchangeRate = expense.exchangeRate;
        _convertedAmount = expense.convertedAmount;
        
        // Load Payers
        _selectedPayers.clear();
        _payerAmountControllers.clear();
        for (final entry in expense.payers.entries) {
          _selectedPayers[entry.key] = true;
          final controller = TextEditingController(text: entry.value.toStringAsFixed(2));
          _payerAmountControllers[entry.key] = controller;
        }

        // Load Splits
        _selectedMembers.clear();
        _splitControllers.clear();
        
        // Determine split type from the first split (assuming uniform type)
        if (expense.splits.isNotEmpty) {
          _splitType = expense.splits.values.first.type;
        }

        for (final entry in expense.splits.entries) {
          _selectedMembers[entry.key] = true;
          String text = '';
          if (_splitType == SplitType.percentage) {
             text = entry.value.percentage?.toString() ?? '';
          } else if (_splitType == SplitType.exact) {
             text = entry.value.amount.toString();
          }
          final controller = TextEditingController(text: text);
          _splitControllers[entry.key] = controller;
        }
        
        _isDataLoaded = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading expense: $e')),
        );
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
