import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/services/exchange_rate_service.dart';

class SplitSelectorModal extends StatefulWidget {
  final ExpenseGroup group;
  final double amount;
  final String currency;
  final Map<String, bool> selectedMembers;
  final Map<String, TextEditingController> splitControllers;
  final SplitType initialSplitType;
  final Function(SplitType, Map<String, bool>) onSplitChanged;

  const SplitSelectorModal({
    super.key,
    required this.group,
    required this.amount,
    required this.currency,
    required this.selectedMembers,
    required this.splitControllers,
    required this.initialSplitType,
    required this.onSplitChanged,
  });

  @override
  State<SplitSelectorModal> createState() => _SplitSelectorModalState();
}

class _SplitSelectorModalState extends State<SplitSelectorModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SplitType _currentSplitType;
  late Map<String, bool> _localSelectedMembers;

  @override
  void initState() {
    super.initState();
    _currentSplitType = widget.initialSplitType;
    _localSelectedMembers = Map.from(widget.selectedMembers);
    
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = _currentSplitType.index;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentSplitType = SplitType.values[_tabController.index];
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _submit() {
    widget.onSplitChanged(_currentSplitType, _localSelectedMembers);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Text(
                  'Split options',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: _submit,
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Equally'),
              Tab(text: 'Exact Amounts'),
              Tab(text: 'Percentages'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEqualSplitTab(),
                _buildExactSplitTab(),
                _buildPercentageSplitTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqualSplitTab() {
    final selectedCount = _localSelectedMembers.values.where((v) => v).length;
    final amountPerPerson = selectedCount > 0 ? widget.amount / selectedCount : 0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: widget.group.members.entries.map((entry) {
        final isSelected = _localSelectedMembers[entry.key] ?? false;
        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              _localSelectedMembers[entry.key] = value ?? false;
            });
          },
          title: Text(entry.value.displayName),
          secondary: CircleAvatar(
            backgroundColor: AppColors.primaryLight,
            child: Text(
              entry.value.displayName[0].toUpperCase(),
              style: const TextStyle(color: AppColors.primaryDark),
            ),
          ),
          subtitle: isSelected
              ? Text('${ExchangeRateService.getCurrencySymbol(widget.currency)}${amountPerPerson.toStringAsFixed(2)}')
              : null,
        );
      }).toList(),
    );
  }

  Widget _buildExactSplitTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: widget.group.members.entries.map((entry) {
        final controller = widget.splitControllers[entry.key];
        // Ensure controller exists (it should from parent)
        if (controller == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  entry.value.displayName[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(entry.value.displayName),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    isDense: true,
                    prefixText: '${ExchangeRateService.getCurrencySymbol(widget.currency)} ',
                    hintText: '0.00',
                  ),
                  onChanged: (val) {
                    // Auto-select if amount > 0
                    if ((double.tryParse(val) ?? 0) > 0) {
                      _localSelectedMembers[entry.key] = true;
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPercentageSplitTab() {
     return ListView(
      padding: const EdgeInsets.all(24),
      children: widget.group.members.entries.map((entry) {
         final controller = widget.splitControllers[entry.key];
        if (controller == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  entry.value.displayName[0].toUpperCase(),
                  style: const TextStyle(color: AppColors.primaryDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(entry.value.displayName),
              ),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    isDense: true,
                    suffixText: '%',
                    hintText: '0',
                  ),
                   onChanged: (val) {
                    if ((double.tryParse(val) ?? 0) > 0) {
                      _localSelectedMembers[entry.key] = true;
                    }
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
