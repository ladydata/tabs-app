import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabs/models/models.dart';
import 'package:tabs/widgets/expense/split_selector_modal.dart';

void main() {
  final now = DateTime.now();
  final group = ExpenseGroup(
    id: 'group1',
    name: 'Test Group',
    currency: 'USD',
    members: {
      'p1': GroupMember(userId: 'p1', displayName: 'Person 1', email: 'p1@test.com', joinedAt: now),
      'p2': GroupMember(userId: 'p2', displayName: 'Person 2', email: 'p2@test.com', joinedAt: now),
    },
    memberIds: ['p1', 'p2'],
    createdBy: 'p1',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    // Set a large enough surface for all tests to avoid overflow
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(1080, 1920);
    binding.window.devicePixelRatioTestValue = 1.0;
  });

  tearDown(() {
    final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });

  testWidgets('Scenario 1: User selects equal split with all members checked', (WidgetTester tester) async {
    Map<String, bool> resultingSelection = {};
    SplitType resultingType = SplitType.equal;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => SplitSelectorModal(
                    group: group,
                    amount: 50.0,
                    currency: 'USD',
                    selectedMembers: {'p1': true, 'p2': true}, // Default state
                    splitControllers: {
                      'p1': TextEditingController(),
                      'p2': TextEditingController(),
                    },
                    initialSplitType: SplitType.equal,
                    onSplitChanged: (type, selection) {
                      resultingType = type;
                      resultingSelection = selection;
                    },
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Verify default is Equal tab
    expect(find.text('Equally'), findsOneWidget);
    // Verify both checked by default for Equal
    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    
    // Click Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Verify result
    expect(resultingType, SplitType.equal);
    expect(resultingSelection['p1'], true);
    expect(resultingSelection['p2'], true);
  });

  testWidgets('Scenario 2: User selects unequal split (\$30/\$20)', (WidgetTester tester) async {
    Map<String, bool> resultingSelection = {};
    SplitType resultingType = SplitType.equal;
    final controllers = {
      'p1': TextEditingController(),
      'p2': TextEditingController(),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => SplitSelectorModal(
                    group: group,
                    amount: 50.0,
                    currency: 'USD',
                    selectedMembers: {'p1': true, 'p2': true},
                    splitControllers: controllers,
                    initialSplitType: SplitType.equal,
                    onSplitChanged: (type, selection) {
                      resultingType = type;
                      resultingSelection = selection;
                    },
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Switch to Exact Amounts
    await tester.tap(find.text('Exact Amounts'));
    await tester.pumpAndSettle();

    // Check checkboxes to enable inputs
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(0)); // check p1
    await tester.tap(checkboxes.at(1)); // check p2
    await tester.pump();

    // Enter amounts
    final inputs = find.byType(TextField);
    await tester.enterText(inputs.at(0), '30');
    await tester.enterText(inputs.at(1), '20');
    await tester.pump();

    // Click Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Verify result
    expect(resultingType, SplitType.exact);
    expect(resultingSelection['p1'], true);
    expect(resultingSelection['p2'], true); // Both selected
    
    // Verify controllers updated (persistence test)
    expect(controllers['p1']!.text, '30');
    expect(controllers['p2']!.text, '20');
  });

  testWidgets('Scenario 3: User selects percentage (10% / 90%)', (WidgetTester tester) async {
    Map<String, bool> resultingSelection = {};
    SplitType resultingType = SplitType.equal;
    final controllers = {
      'p1': TextEditingController(),
      'p2': TextEditingController(),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => SplitSelectorModal(
                    group: group,
                    amount: 50.0,
                    currency: 'USD',
                    selectedMembers: {'p1': true, 'p2': true},
                    splitControllers: controllers,
                    initialSplitType: SplitType.equal,
                    onSplitChanged: (type, selection) {
                      resultingType = type;
                      resultingSelection = selection;
                    },
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    // Open modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // Switch to Percentages
    await tester.tap(find.text('Percentages'));
    await tester.pumpAndSettle();

    // Check checkboxes
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(0));
    await tester.tap(checkboxes.at(1));
    await tester.pump();

    // Enter percentages
    final inputs = find.byType(TextField);
    await tester.enterText(inputs.at(0), '10');
    await tester.enterText(inputs.at(1), '90');
    await tester.pump();

    // Click Done
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Verify result
    expect(resultingType, SplitType.percentage);
    expect(resultingSelection['p1'], true); // p1 pays 10%
    expect(resultingSelection['p2'], true); // p2 pays 90%
    
    expect(controllers['p1']!.text, '10');
    expect(controllers['p2']!.text, '90');
  });
  
  testWidgets('Persistence Test: Reopening modal retains previous selection', (WidgetTester tester) async {
      // Simulate state in parent widget
      SplitType currentType = SplitType.exact;
      Map<String, bool> selection = {'p1': true, 'p2': false};
      final controllers = {
        'p1': TextEditingController(text: '50'),
        'p2': TextEditingController(text: ''),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Make sure it can expand
                    builder: (ctx) => SplitSelectorModal(
                      group: group,
                      amount: 50.0,
                      currency: 'USD',
                      selectedMembers: selection, // Pass in persisted selection
                      splitControllers: controllers,
                      initialSplitType: currentType, // Pass in persisted type
                      onSplitChanged: (type, sel) {},
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open modal with existing state (Exact split, p1 paying 50)
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Verify we are on Exact tab
      // Verify p1 is checked and has value 50
      expect(find.text('50'), findsOneWidget);
      
      // Verify exact tab is active (Checkboxes present)
      expect(find.byType(Checkbox), findsNWidgets(2));
      
      // Verify p1 checkbox is checked
      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checkboxes.first.value, true); // p1
      expect(checkboxes.last.value, false); // p2
    });
}
