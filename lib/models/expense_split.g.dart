// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_split.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExpenseSplitImpl _$$ExpenseSplitImplFromJson(Map<String, dynamic> json) =>
    _$ExpenseSplitImpl(
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: $enumDecode(_$SplitTypeEnumMap, json['type']),
      percentage: (json['percentage'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$ExpenseSplitImplToJson(_$ExpenseSplitImpl instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'amount': instance.amount,
      'type': _$SplitTypeEnumMap[instance.type]!,
      'percentage': instance.percentage,
    };

const _$SplitTypeEnumMap = {
  SplitType.equal: 'equal',
  SplitType.percentage: 'percentage',
  SplitType.exact: 'exact',
};
