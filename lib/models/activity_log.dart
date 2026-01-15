import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tabs/models/user.dart';

part 'activity_log.freezed.dart';
part 'activity_log.g.dart';

enum ActivityType {
  expenseAdded,
  expenseUpdated,
  expenseDeleted,
  settlementAdded,
  memberJoined,
  memberLeft,
  groupUpdated,
}

@freezed
class ActivityLog with _$ActivityLog {
  const factory ActivityLog({
    required String id,
    required String groupId,
    required ActivityType type,
    required String actorUserId,
    required String actorName,
    required Map<String, dynamic> details,
    @TimestampConverter() required DateTime createdAt,
  }) = _ActivityLog;

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);

  factory ActivityLog.fromFirestore(DocumentSnapshot doc, String groupId) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLog(
      id: doc.id,
      groupId: groupId,
      type: ActivityType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ActivityType.expenseAdded,
      ),
      actorUserId: data['actorUserId'] as String,
      actorName: data['actorName'] as String,
      details: data['details'] as Map<String, dynamic>? ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
