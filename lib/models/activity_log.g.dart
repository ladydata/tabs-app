// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ActivityLogImpl _$$ActivityLogImplFromJson(Map<String, dynamic> json) =>
    _$ActivityLogImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      type: $enumDecode(_$ActivityTypeEnumMap, json['type']),
      actorUserId: json['actorUserId'] as String,
      actorName: json['actorName'] as String,
      details: json['details'] as Map<String, dynamic>,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$$ActivityLogImplToJson(_$ActivityLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'type': _$ActivityTypeEnumMap[instance.type]!,
      'actorUserId': instance.actorUserId,
      'actorName': instance.actorName,
      'details': instance.details,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$ActivityTypeEnumMap = {
  ActivityType.expenseAdded: 'expenseAdded',
  ActivityType.expenseUpdated: 'expenseUpdated',
  ActivityType.expenseDeleted: 'expenseDeleted',
  ActivityType.settlementAdded: 'settlementAdded',
  ActivityType.memberJoined: 'memberJoined',
  ActivityType.memberLeft: 'memberLeft',
  ActivityType.groupUpdated: 'groupUpdated',
};
