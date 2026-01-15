import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tabs/models/group_member.dart';
import 'package:tabs/models/user.dart';

part 'group.freezed.dart';
part 'group.g.dart';

@freezed
class ExpenseGroup with _$ExpenseGroup {
  const factory ExpenseGroup({
    required String id,
    required String name,
    String? description,
    required String currency,
    required List<String> memberIds,
    required Map<String, GroupMember> members,
    required String createdBy,
    @TimestampConverter() required DateTime createdAt,
    @TimestampConverter() required DateTime updatedAt,
  }) = _ExpenseGroup;

  factory ExpenseGroup.fromJson(Map<String, dynamic> json) =>
      _$ExpenseGroupFromJson(json);

  factory ExpenseGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse members map
    final membersData = data['members'] as Map<String, dynamic>? ?? {};
    final members = membersData.map((key, value) => MapEntry(
      key,
      GroupMember.fromJson(value as Map<String, dynamic>),
    ));

    return ExpenseGroup(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String?,
      currency: data['currency'] as String,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      members: members,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }
}
