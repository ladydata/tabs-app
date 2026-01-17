import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tabs/models/models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============ Groups ============

  CollectionReference<Map<String, dynamic>> get _groupsCollection =>
      _firestore.collection('groups');

  Stream<List<ExpenseGroup>> getUserGroups(String userId) {
    return _groupsCollection
        .where('memberIds', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ExpenseGroup.fromFirestore(doc)).toList());
  }

  Future<ExpenseGroup?> getGroup(String groupId) async {
    final doc = await _groupsCollection.doc(groupId).get();
    if (!doc.exists) return null;
    return ExpenseGroup.fromFirestore(doc);
  }

  Stream<ExpenseGroup?> groupStream(String groupId) {
    return _groupsCollection.doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ExpenseGroup.fromFirestore(doc);
    });
  }

  Future<String> createGroup({
    required String name,
    String? description,
    required String currency,
    required String creatorId,
    required String creatorName,
    required String creatorEmail,
  }) async {
    final now = DateTime.now();
    final docRef = _groupsCollection.doc();

    final member = GroupMember(
      userId: creatorId,
      displayName: creatorName,
      email: creatorEmail,
      joinedAt: now,
      role: MemberRole.admin,
    );

    await docRef.set({
      'name': name,
      'description': description,
      'currency': currency,
      'memberIds': [creatorId],
      'members': {
        creatorId: {
          'userId': creatorId,
          'displayName': creatorName,
          'email': creatorEmail,
          'joinedAt': Timestamp.fromDate(now),
          'role': 'admin',
        },
      },
      'createdBy': creatorId,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return docRef.id;
  }

  Future<void> updateGroup(String groupId, {String? name, String? description}) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;

    await _groupsCollection.doc(groupId).update(updates);
  }

  Future<void> addMemberToGroup(
    String groupId,
    String userId,
    String displayName,
    String email,
  ) async {
    final now = DateTime.now();
    await _groupsCollection.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'members.$userId': {
        'userId': userId,
        'displayName': displayName,
        'email': email,
        'joinedAt': Timestamp.fromDate(now),
        'role': 'member',
      },
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> removeMemberFromGroup(String groupId, String userId) async {
    await _groupsCollection.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'members.$userId': FieldValue.delete(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteGroup(String groupId) async {
    // Delete all expenses
    final expenses = await _groupsCollection
        .doc(groupId)
        .collection('expenses')
        .get();
    for (final doc in expenses.docs) {
      await doc.reference.delete();
    }

    // Delete all settlements
    final settlements = await _groupsCollection
        .doc(groupId)
        .collection('settlements')
        .get();
    for (final doc in settlements.docs) {
      await doc.reference.delete();
    }

    // Delete all activity
    final activity = await _groupsCollection
        .doc(groupId)
        .collection('activity')
        .get();
    for (final doc in activity.docs) {
      await doc.reference.delete();
    }

    // Delete the group
    await _groupsCollection.doc(groupId).delete();
  }

  // ============ Expenses ============

  CollectionReference<Map<String, dynamic>> _expensesCollection(String groupId) =>
      _groupsCollection.doc(groupId).collection('expenses');

  Stream<List<Expense>> getGroupExpenses(String groupId) {
    return _expensesCollection(groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Expense.fromFirestore(doc, groupId)).toList());
  }

  Future<Expense?> getExpense(String groupId, String expenseId) async {
    final doc = await _expensesCollection(groupId).doc(expenseId).get();
    if (!doc.exists) return null;
    return Expense.fromFirestore(doc, groupId);
  }

  Future<String> createExpense({
    required String groupId,
    required String title,
    String? category,
    String? notes,
    required double amount,
    required String currency,
    required double convertedAmount,
    required double exchangeRate,
    required DateTime date,
    required String paidBy,
    required Map<String, double> payers,
    required Map<String, ExpenseSplit> splits,
    required String createdBy,
  }) async {
    final now = DateTime.now();
    final docRef = _expensesCollection(groupId).doc();

    final splitsData = splits.map((key, value) => MapEntry(key, {
      'userId': value.userId,
      'amount': value.amount,
      'type': value.type.name,
      if (value.percentage != null) 'percentage': value.percentage,
    }));

    await docRef.set({
      'title': title,
      'category': category,
      'notes': notes,
      'amount': amount,
      'currency': currency,
      'convertedAmount': convertedAmount,
      'exchangeRate': exchangeRate,
      'date': Timestamp.fromDate(date),
      'paidBy': paidBy,
      'payers': payers,
      'splits': splitsData,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    // Update group's updatedAt
    await _groupsCollection.doc(groupId).update({
      'updatedAt': Timestamp.fromDate(now),
    });

    return docRef.id;
  }

  Future<void> updateExpense({
    required String groupId,
    required String expenseId,
    String? title,
    String? category,
    String? notes,
    double? amount,
    String? currency,
    double? convertedAmount,
    double? exchangeRate,
    DateTime? date,
    String? paidBy,
    Map<String, double>? payers,
    Map<String, ExpenseSplit>? splits,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    };
    if (title != null) updates['title'] = title;
    if (category != null) updates['category'] = category;
    if (notes != null) updates['notes'] = notes;
    if (amount != null) updates['amount'] = amount;
    if (currency != null) updates['currency'] = currency;
    if (convertedAmount != null) updates['convertedAmount'] = convertedAmount;
    if (exchangeRate != null) updates['exchangeRate'] = exchangeRate;
    if (date != null) updates['date'] = Timestamp.fromDate(date);
    if (paidBy != null) updates['paidBy'] = paidBy;
    if (payers != null) updates['payers'] = payers;
    if (splits != null) {
      updates['splits'] = splits.map((key, value) => MapEntry(key, {
        'userId': value.userId,
        'amount': value.amount,
        'type': value.type.name,
        if (value.percentage != null) 'percentage': value.percentage,
      }));
    }

    await _expensesCollection(groupId).doc(expenseId).update(updates);
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    await _expensesCollection(groupId).doc(expenseId).delete();
    await _groupsCollection.doc(groupId).update({
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============ Settlements ============

  CollectionReference<Map<String, dynamic>> _settlementsCollection(String groupId) =>
      _groupsCollection.doc(groupId).collection('settlements');

  Stream<List<Settlement>> getGroupSettlements(String groupId) {
    return _settlementsCollection(groupId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Settlement.fromFirestore(doc, groupId)).toList());
  }

  Future<String> createSettlement({
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required DateTime date,
    String? notes,
    required String createdBy,
  }) async {
    final now = DateTime.now();
    final docRef = _settlementsCollection(groupId).doc();

    await docRef.set({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(now),
    });

    await _groupsCollection.doc(groupId).update({
      'updatedAt': Timestamp.fromDate(now),
    });

    return docRef.id;
  }

  Future<void> deleteSettlement(String groupId, String settlementId) async {
    await _settlementsCollection(groupId).doc(settlementId).delete();
  }

  // ============ Activity Log ============

  CollectionReference<Map<String, dynamic>> _activityCollection(String groupId) =>
      _groupsCollection.doc(groupId).collection('activity');

  Stream<List<ActivityLog>> getGroupActivity(String groupId, {int limit = 50}) {
    return _activityCollection(groupId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ActivityLog.fromFirestore(doc, groupId)).toList());
  }

  Future<void> logActivity({
    required String groupId,
    required ActivityType type,
    required String actorUserId,
    required String actorName,
    required Map<String, dynamic> details,
  }) async {
    await _activityCollection(groupId).add({
      'type': type.name,
      'actorUserId': actorUserId,
      'actorName': actorName,
      'details': details,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ============ User Lookup ============

  Future<AppUser?> findUserByEmail(String email) async {
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return AppUser.fromFirestore(snapshot.docs.first);
  }
}
