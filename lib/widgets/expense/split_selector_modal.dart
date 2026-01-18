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
  
  // Independent selection state for each tab
  late Map<String, bool> _equalSelected;
  late Map<String, bool> _exactSelected;
  late Map<String, bool> _percentSelected;
  
  // Separate controllers
  late Map<String, TextEditingController> _exactControllers;
  late Map<String, TextEditingController> _percentControllers;

  // Explicitly map SplitType to Tab Index to avoid mismatch with Enum order
  int _getTabIndex(SplitType type) {
    switch (type) {
      case SplitType.equal: return 0;
      case SplitType.exact: return 1;
      case SplitType.percentage: return 2;
    }
  }

  SplitType _getSplitTypeAndIndex(int index) {
    switch (index) {
      case 0: return SplitType.equal;
      case 1: return SplitType.exact;
      case 2: return SplitType.percentage;
      default: return SplitType.equal;
    }
  }

  @override
  void initState() {
    super.initState();
    _currentSplitType = widget.initialSplitType;
    
    // Initialize independent selections based on current active type 
    // ... (rest of initialization) ...
    // ...
    // 1. Equal Selection
    if (widget.initialSplitType == SplitType.equal) {
       _equalSelected = Map.from(widget.selectedMembers);
    } else {
       // Default equal to unchecked as requested
       _equalSelected = {for (var id in widget.group.memberIds) id: false};
    }

    // 2. Exact Selection
    if (widget.initialSplitType == SplitType.exact) {
       _exactSelected = Map.from(widget.selectedMembers);
    } else {
       // For exact, start with nobody selected unless they have a value entered
       _exactSelected = {for (var id in widget.group.memberIds) id: false};
    }

    // 3. Percent Selection
    if (widget.initialSplitType == SplitType.percentage) {
      _percentSelected = Map.from(widget.selectedMembers);
    } else {
      _percentSelected = {for (var id in widget.group.memberIds) id: false};
    }
    
    // Initialize local controllers
    _exactControllers = {};
    _percentControllers = {};
    
    for (final memberId in widget.group.memberIds) {
      _exactControllers[memberId] = TextEditingController();
      _percentControllers[memberId] = TextEditingController();
      
      // Load existing values into controllers and auto-select if value exists
      if (widget.initialSplitType == SplitType.exact) {
        final text = widget.splitControllers[memberId]?.text ?? '';
        _exactControllers[memberId]?.text = text;
        if (text.isNotEmpty && (double.tryParse(text) ?? 0) > 0) {
           _exactSelected[memberId] = true;
        }
      } else if (widget.initialSplitType == SplitType.percentage) {
        final text = widget.splitControllers[memberId]?.text ?? '';
        _percentControllers[memberId]?.text = text;
        if (text.isNotEmpty && (double.tryParse(text) ?? 0) > 0) {
           _percentSelected[memberId] = true;
        }
      }
    }
    
    _tabController = TabController(length: 3, vsync: this);
    _tabController.index = _getTabIndex(_currentSplitType);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentSplitType = _getSplitTypeAndIndex(_tabController.index);
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _exactControllers.values) controller.dispose();
    for (final controller in _percentControllers.values) controller.dispose();
    super.dispose();
  }

  void _submit() {
    // Commit values to parent controllers based on selected type
    for (final memberId in widget.group.memberIds) {
      final parentController = widget.splitControllers[memberId];
      if (parentController == null) continue;

      if (_currentSplitType == SplitType.exact) {
        parentController.text = _exactControllers[memberId]?.text ?? '';
      } else if (_currentSplitType == SplitType.percentage) {
        parentController.text = _percentControllers[memberId]?.text ?? '';
      } else {
        parentController.clear();
      }
    }

    // Return the selection map corresponding to the active tab
    Map<String, bool> finalSelectedMembers;
    switch (_currentSplitType) {
      case SplitType.equal:
        finalSelectedMembers = _equalSelected;
        break;
      case SplitType.exact:
        // Re-calculate selection based on values > 0
        finalSelectedMembers = {};
        for (final memberId in widget.group.memberIds) {
          final val = double.tryParse(_exactControllers[memberId]?.text ?? '') ?? 0;
          finalSelectedMembers[memberId] = val > 0;
        }
        break;
      case SplitType.percentage:
        // Re-calculate selection based on values > 0
        finalSelectedMembers = {};
        for (final memberId in widget.group.memberIds) {
          final val = double.tryParse(_percentControllers[memberId]?.text ?? '') ?? 0;
          finalSelectedMembers[memberId] = val > 0;
        }
        break;
    }

    widget.onSplitChanged(_currentSplitType, finalSelectedMembers);
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
    final selectedCount = _equalSelected.values.where((v) => v).length;
    final amountPerPerson = selectedCount > 0 ? widget.amount / selectedCount : 0;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: widget.group.members.entries.map((entry) {
        final isSelected = _equalSelected[entry.key] ?? false;
        return CheckboxListTile(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              _equalSelected[entry.key] = value ?? false;
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
        final controller = _exactControllers[entry.key];
        
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
                    // Auto-select is implicit on submission
                    setState(() {}); // Rebuild to update UI if needed
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
         final controller = _percentControllers[entry.key];
         
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
                    setState(() {}); // Rebuild
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
