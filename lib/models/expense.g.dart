// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ExpenseImpl _$$ExpenseImplFromJson(Map<String, dynamic> json) =>
    _$ExpenseImpl(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      convertedAmount: (json['convertedAmount'] as num).toDouble(),
      exchangeRate: (json['exchangeRate'] as num).toDouble(),
      date: const TimestampConverter().fromJson(json['date']),
      paidBy: json['paidBy'] as String,
      splits: (json['splits'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, ExpenseSplit.fromJson(e as Map<String, dynamic>)),
      ),
      createdBy: json['createdBy'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$ExpenseImplToJson(_$ExpenseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'title': instance.title,
      'notes': instance.notes,
      'amount': instance.amount,
      'currency': instance.currency,
      'convertedAmount': instance.convertedAmount,
      'exchangeRate': instance.exchangeRate,
      'date': const TimestampConverter().toJson(instance.date),
      'paidBy': instance.paidBy,
      'splits': instance.splits,
      'createdBy': instance.createdBy,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
    };
