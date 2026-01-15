// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ExpenseGroup _$ExpenseGroupFromJson(Map<String, dynamic> json) {
  return _ExpenseGroup.fromJson(json);
}

/// @nodoc
mixin _$ExpenseGroup {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  List<String> get memberIds => throw _privateConstructorUsedError;
  Map<String, GroupMember> get members => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this ExpenseGroup to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ExpenseGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpenseGroupCopyWith<ExpenseGroup> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpenseGroupCopyWith<$Res> {
  factory $ExpenseGroupCopyWith(
    ExpenseGroup value,
    $Res Function(ExpenseGroup) then,
  ) = _$ExpenseGroupCopyWithImpl<$Res, ExpenseGroup>;
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String currency,
    List<String> memberIds,
    Map<String, GroupMember> members,
    String createdBy,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class _$ExpenseGroupCopyWithImpl<$Res, $Val extends ExpenseGroup>
    implements $ExpenseGroupCopyWith<$Res> {
  _$ExpenseGroupCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExpenseGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? currency = null,
    Object? memberIds = null,
    Object? members = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            memberIds: null == memberIds
                ? _value.memberIds
                : memberIds // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            members: null == members
                ? _value.members
                : members // ignore: cast_nullable_to_non_nullable
                      as Map<String, GroupMember>,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExpenseGroupImplCopyWith<$Res>
    implements $ExpenseGroupCopyWith<$Res> {
  factory _$$ExpenseGroupImplCopyWith(
    _$ExpenseGroupImpl value,
    $Res Function(_$ExpenseGroupImpl) then,
  ) = __$$ExpenseGroupImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String? description,
    String currency,
    List<String> memberIds,
    Map<String, GroupMember> members,
    String createdBy,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class __$$ExpenseGroupImplCopyWithImpl<$Res>
    extends _$ExpenseGroupCopyWithImpl<$Res, _$ExpenseGroupImpl>
    implements _$$ExpenseGroupImplCopyWith<$Res> {
  __$$ExpenseGroupImplCopyWithImpl(
    _$ExpenseGroupImpl _value,
    $Res Function(_$ExpenseGroupImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExpenseGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? currency = null,
    Object? memberIds = null,
    Object? members = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ExpenseGroupImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        memberIds: null == memberIds
            ? _value._memberIds
            : memberIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        members: null == members
            ? _value._members
            : members // ignore: cast_nullable_to_non_nullable
                  as Map<String, GroupMember>,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ExpenseGroupImpl implements _ExpenseGroup {
  const _$ExpenseGroupImpl({
    required this.id,
    required this.name,
    this.description,
    required this.currency,
    required final List<String> memberIds,
    required final Map<String, GroupMember> members,
    required this.createdBy,
    @TimestampConverter() required this.createdAt,
    @TimestampConverter() required this.updatedAt,
  }) : _memberIds = memberIds,
       _members = members;

  factory _$ExpenseGroupImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExpenseGroupImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  final String currency;
  final List<String> _memberIds;
  @override
  List<String> get memberIds {
    if (_memberIds is EqualUnmodifiableListView) return _memberIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_memberIds);
  }

  final Map<String, GroupMember> _members;
  @override
  Map<String, GroupMember> get members {
    if (_members is EqualUnmodifiableMapView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_members);
  }

  @override
  final String createdBy;
  @override
  @TimestampConverter()
  final DateTime createdAt;
  @override
  @TimestampConverter()
  final DateTime updatedAt;

  @override
  String toString() {
    return 'ExpenseGroup(id: $id, name: $name, description: $description, currency: $currency, memberIds: $memberIds, members: $members, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseGroupImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            const DeepCollectionEquality().equals(
              other._memberIds,
              _memberIds,
            ) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    description,
    currency,
    const DeepCollectionEquality().hash(_memberIds),
    const DeepCollectionEquality().hash(_members),
    createdBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of ExpenseGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseGroupImplCopyWith<_$ExpenseGroupImpl> get copyWith =>
      __$$ExpenseGroupImplCopyWithImpl<_$ExpenseGroupImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExpenseGroupImplToJson(this);
  }
}

abstract class _ExpenseGroup implements ExpenseGroup {
  const factory _ExpenseGroup({
    required final String id,
    required final String name,
    final String? description,
    required final String currency,
    required final List<String> memberIds,
    required final Map<String, GroupMember> members,
    required final String createdBy,
    @TimestampConverter() required final DateTime createdAt,
    @TimestampConverter() required final DateTime updatedAt,
  }) = _$ExpenseGroupImpl;

  factory _ExpenseGroup.fromJson(Map<String, dynamic> json) =
      _$ExpenseGroupImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  String get currency;
  @override
  List<String> get memberIds;
  @override
  Map<String, GroupMember> get members;
  @override
  String get createdBy;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;

  /// Create a copy of ExpenseGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpenseGroupImplCopyWith<_$ExpenseGroupImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
