import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tabs/models/expense.dart';
import 'package:tabs/models/expense_split.dart';

void main() {
  group('Expense Model Tests', () {
    test('Legacy Expense (single paidBy) is correctly parsed', () async {
      final instance = FakeFirebaseFirestore();
      final docRef = await instance.collection('expenses').add({
        'title': 'Legacy Lunch',
        'amount': 30.0,
        'currency': 'USD',
        'convertedAmount': 30.0,
        'exchangeRate': 1.0,
        'date': Timestamp.now(),
        'paidBy': 'user1',
        'splits': {},
        'createdBy': 'user1',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        // No 'payers' field
      });

      final doc = await docRef.get();
      final expense = Expense.fromFirestore(doc, 'group1');

      expect(expense.payers, {'user1': 30.0});
      expect(expense.paidBy, 'user1');
    });

    test('Modern Expense (multiple payers) is correctly parsed', () async {
      final instance = FakeFirebaseFirestore();
      final docRef = await instance.collection('expenses').add({
        'title': 'Team Dinner',
        'amount': 100.0,
        'currency': 'USD',
        'convertedAmount': 100.0,
        'exchangeRate': 1.0,
        'date': Timestamp.now(),
        'paidBy': 'user1', // Legacy field still populated
        'payers': {
          'user1': 60.0,
          'user2': 40.0,
        },
        'splits': {},
        'createdBy': 'user1',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final doc = await docRef.get();
      final expense = Expense.fromFirestore(doc, 'group1');

      expect(expense.payers, {
        'user1': 60.0,
        'user2': 40.0,
      });
      expect(expense.amount, 100.0);
    });

    test('Expense Split parsing', () async {
      final instance = FakeFirebaseFirestore();
      final docRef = await instance.collection('expenses').add({
        'title': 'Split Lunch',
        'amount': 20.0,
        'currency': 'USD',
        'convertedAmount': 20.0,
        'exchangeRate': 1.0,
        'date': Timestamp.now(),
        'paidBy': 'user1',
        'payers': {'user1': 20.0},
        'splits': {
          'user1': {
            'userId': 'user1',
            'amount': 10.0,
            'type': 'equal',
          },
          'user2': {
            'userId': 'user2',
            'amount': 10.0,
            'type': 'equal',
          }
        },
        'createdBy': 'user1',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      final doc = await docRef.get();
      final expense = Expense.fromFirestore(doc, 'group1');

      expect(expense.splits.length, 2);
      expect(expense.splits['user1']?.amount, 10.0);
      expect(expense.splits['user1']?.type, SplitType.equal);
    });
  });
}
