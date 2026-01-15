import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tabs/models/user.dart';

part 'group_member.freezed.dart';
part 'group_member.g.dart';

enum MemberRole { admin, member }

@freezed
class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String userId,
    required String displayName,
    required String email,
    @TimestampConverter() required DateTime joinedAt,
    @Default(MemberRole.member) MemberRole role,
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
