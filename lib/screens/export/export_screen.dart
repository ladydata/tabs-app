import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:tabs/config/theme.dart';
import 'package:tabs/providers/expenses_provider.dart';
import 'package:tabs/providers/groups_provider.dart';
import 'package:tabs/services/export_service.dart';
import 'package:tabs/widgets/common/loading_widget.dart';

// Provider for ExportService
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

class ExportScreen extends ConsumerStatefulWidget {
  final String groupId;

  const ExportScreen({super.key, required this.groupId});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Default to this month
    final now = DateTime.now();
    _selectedDateRange = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  Future<void> _export(bool isPdf) async {
    if (_selectedDateRange == null) return;

    setState(() => _isLoading = true);
    try {
      final exportService = ref.read(exportServiceProvider);
      final expensesAsync = ref.read(groupExpensesProvider(widget.groupId));
      
      // We need to fetch expenses if they aren't loaded or filter them locally
      // Ideally we should have a query for date range, but for now filtering in memory is fine for typical group sizes
      
      final allExpenses = expensesAsync.valueOrNull ?? [];
      final filteredExpenses = allExpenses.where((e) {
        return e.date.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) &&
               e.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();

      if (filteredExpenses.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No expenses found in this date range')),
          );
        }
        return;
      }

      final group = await ref.read(groupProvider(widget.groupId).future);
      if (group == null) throw Exception('Group not found');

      if (isPdf) {
        await exportService.exportToPdf(
          group: group,
          expenses: filteredExpenses,
          startDate: _selectedDateRange!.start,
          endDate: _selectedDateRange!.end,
        );
      } else {
        await exportService.exportToCsv(
          group: group,
          expenses: filteredExpenses,
          startDate: _selectedDateRange!.start,
          endDate: _selectedDateRange!.end,
        );
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.file_download_outlined, size: 64, color: AppColors.primary),
            const SizedBox(height: 24),
            Text(
              'Generate Expense Report',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a date range to export your group expenses.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Date Range Selector
            InkWell(
              onTap: _selectDateRange,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.textDisabled),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range, color: AppColors.primary),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date Range', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton.icon(
                onPressed: () => _export(true),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export as PDF'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _export(false),
                icon: const Icon(Icons.table_view),
                label: const Text('Export as CSV'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
