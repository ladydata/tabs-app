// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Expense _$ExpenseFromJson(Map<String, dynamic> json) {
  return _Expense.fromJson(json);
}

/// @nodoc
mixin _$Expense {
  String get id => throw _privateConstructorUsedError;
  String get groupId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get currency => throw _privateConstructorUsedError;
  double get convertedAmount => throw _privateConstructorUsedError;
  double get exchangeRate => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get date => throw _privateConstructorUsedError;
  String get paidBy => throw _privateConstructorUsedError;
  Map<String, double> get payers =>
      throw _privateConstructorUsedError; // userId -> amount in original currency
  Map<String, ExpenseSplit> get splits => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExpenseCopyWith<Expense> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExpenseCopyWith<$Res> {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) then) =
      _$ExpenseCopyWithImpl<$Res, Expense>;
  @useResult
  $Res call({
    String id,
    String groupId,
    String title,
    String? notes,
    double amount,
    String currency,
    double convertedAmount,
    double exchangeRate,
    @TimestampConverter() DateTime date,
    String paidBy,
    Map<String, double> payers,
    Map<String, ExpenseSplit> splits,
    String createdBy,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class _$ExpenseCopyWithImpl<$Res, $Val extends Expense>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? title = null,
    Object? notes = freezed,
    Object? amount = null,
    Object? currency = null,
    Object? convertedAmount = null,
    Object? exchangeRate = null,
    Object? date = null,
    Object? paidBy = null,
    Object? payers = null,
    Object? splits = null,
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
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            amount: null == amount
                ? _value.amount
                : amount // ignore: cast_nullable_to_non_nullable
                      as double,
            currency: null == currency
                ? _value.currency
                : currency // ignore: cast_nullable_to_non_nullable
                      as String,
            convertedAmount: null == convertedAmount
                ? _value.convertedAmount
                : convertedAmount // ignore: cast_nullable_to_non_nullable
                      as double,
            exchangeRate: null == exchangeRate
                ? _value.exchangeRate
                : exchangeRate // ignore: cast_nullable_to_non_nullable
                      as double,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            paidBy: null == paidBy
                ? _value.paidBy
                : paidBy // ignore: cast_nullable_to_non_nullable
                      as String,
            payers: null == payers
                ? _value.payers
                : payers // ignore: cast_nullable_to_non_nullable
                      as Map<String, double>,
            splits: null == splits
                ? _value.splits
                : splits // ignore: cast_nullable_to_non_nullable
                      as Map<String, ExpenseSplit>,
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
abstract class _$$ExpenseImplCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$$ExpenseImplCopyWith(
    _$ExpenseImpl value,
    $Res Function(_$ExpenseImpl) then,
  ) = __$$ExpenseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String groupId,
    String title,
    String? notes,
    double amount,
    String currency,
    double convertedAmount,
    double exchangeRate,
    @TimestampConverter() DateTime date,
    String paidBy,
    Map<String, double> payers,
    Map<String, ExpenseSplit> splits,
    String createdBy,
    @TimestampConverter() DateTime createdAt,
    @TimestampConverter() DateTime updatedAt,
  });
}

/// @nodoc
class __$$ExpenseImplCopyWithImpl<$Res>
    extends _$ExpenseCopyWithImpl<$Res, _$ExpenseImpl>
    implements _$$ExpenseImplCopyWith<$Res> {
  __$$ExpenseImplCopyWithImpl(
    _$ExpenseImpl _value,
    $Res Function(_$ExpenseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? groupId = null,
    Object? title = null,
    Object? notes = freezed,
    Object? amount = null,
    Object? currency = null,
    Object? convertedAmount = null,
    Object? exchangeRate = null,
    Object? date = null,
    Object? paidBy = null,
    Object? payers = null,
    Object? splits = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$ExpenseImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        amount: null == amount
            ? _value.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as double,
        currency: null == currency
            ? _value.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        convertedAmount: null == convertedAmount
            ? _value.convertedAmount
            : convertedAmount // ignore: cast_nullable_to_non_nullable
                  as double,
        exchangeRate: null == exchangeRate
            ? _value.exchangeRate
            : exchangeRate // ignore: cast_nullable_to_non_nullable
                  as double,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        paidBy: null == paidBy
            ? _value.paidBy
            : paidBy // ignore: cast_nullable_to_non_nullable
                  as String,
        payers: null == payers
            ? _value._payers
            : payers // ignore: cast_nullable_to_non_nullable
                  as Map<String, double>,
        splits: null == splits
            ? _value._splits
            : splits // ignore: cast_nullable_to_non_nullable
                  as Map<String, ExpenseSplit>,
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
class _$ExpenseImpl implements _Expense {
  const _$ExpenseImpl({
    required this.id,
    required this.groupId,
    required this.title,
    this.notes,
    required this.amount,
    required this.currency,
    required this.convertedAmount,
    required this.exchangeRate,
    @TimestampConverter() required this.date,
    required this.paidBy,
    required final Map<String, double> payers,
    required final Map<String, ExpenseSplit> splits,
    required this.createdBy,
    @TimestampConverter() required this.createdAt,
    @TimestampConverter() required this.updatedAt,
  }) : _payers = payers,
       _splits = splits;

  factory _$ExpenseImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExpenseImplFromJson(json);

  @override
  final String id;
  @override
  final String groupId;
  @override
  final String title;
  @override
  final String? notes;
  @override
  final double amount;
  @override
  final String currency;
  @override
  final double convertedAmount;
  @override
  final double exchangeRate;
  @override
  @TimestampConverter()
  final DateTime date;
  @override
  final String paidBy;
  final Map<String, double> _payers;
  @override
  Map<String, double> get payers {
    if (_payers is EqualUnmodifiableMapView) return _payers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_payers);
  }

  // userId -> amount in original currency
  final Map<String, ExpenseSplit> _splits;
  // userId -> amount in original currency
  @override
  Map<String, ExpenseSplit> get splits {
    if (_splits is EqualUnmodifiableMapView) return _splits;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_splits);
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
    return 'Expense(id: $id, groupId: $groupId, title: $title, notes: $notes, amount: $amount, currency: $currency, convertedAmount: $convertedAmount, exchangeRate: $exchangeRate, date: $date, paidBy: $paidBy, payers: $payers, splits: $splits, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExpenseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.convertedAmount, convertedAmount) ||
                other.convertedAmount == convertedAmount) &&
            (identical(other.exchangeRate, exchangeRate) ||
                other.exchangeRate == exchangeRate) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.paidBy, paidBy) || other.paidBy == paidBy) &&
            const DeepCollectionEquality().equals(other._payers, _payers) &&
            const DeepCollectionEquality().equals(other._splits, _splits) &&
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
    groupId,
    title,
    notes,
    amount,
    currency,
    convertedAmount,
    exchangeRate,
    date,
    paidBy,
    const DeepCollectionEquality().hash(_payers),
    const DeepCollectionEquality().hash(_splits),
    createdBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExpenseImplCopyWith<_$ExpenseImpl> get copyWith =>
      __$$ExpenseImplCopyWithImpl<_$ExpenseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExpenseImplToJson(this);
  }
}

abstract class _Expense implements Expense {
  const factory _Expense({
    required final String id,
    required final String groupId,
    required final String title,
    final String? notes,
    required final double amount,
    required final String currency,
    required final double convertedAmount,
    required final double exchangeRate,
    @TimestampConverter() required final DateTime date,
    required final String paidBy,
    required final Map<String, double> payers,
    required final Map<String, ExpenseSplit> splits,
    required final String createdBy,
    @TimestampConverter() required final DateTime createdAt,
    @TimestampConverter() required final DateTime updatedAt,
  }) = _$ExpenseImpl;

  factory _Expense.fromJson(Map<String, dynamic> json) = _$ExpenseImpl.fromJson;

  @override
  String get id;
  @override
  String get groupId;
  @override
  String get title;
  @override
  String? get notes;
  @override
  double get amount;
  @override
  String get currency;
  @override
  double get convertedAmount;
  @override
  double get exchangeRate;
  @override
  @TimestampConverter()
  DateTime get date;
  @override
  String get paidBy;
  @override
  Map<String, double> get payers; // userId -> amount in original currency
  @override
  Map<String, ExpenseSplit> get splits;
  @override
  String get createdBy;
  @override
  @TimestampConverter()
  DateTime get createdAt;
  @override
  @TimestampConverter()
  DateTime get updatedAt;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExpenseImplCopyWith<_$ExpenseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
