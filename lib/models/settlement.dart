import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tabs/models/user.dart';

part 'settlement.freezed.dart';
part 'settlement.g.dart';

@freezed
class Settlement with _$Settlement {
  const factory Settlement({
    required String id,
    required String groupId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    @TimestampConverter() required DateTime date,
    String? notes,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
  }) = _Settlement;

  factory Settlement.fromJson(Map<String, dynamic> json) =>
      _$SettlementFromJson(json);

  factory Settlement.fromFirestore(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>;
    return Settlement(
      id: doc.id,
      groupId: groupId,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      notes: data['notes'] as String?,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
