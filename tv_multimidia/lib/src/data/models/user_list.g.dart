// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserList _$UserListFromJson(Map<String, dynamic> json) => UserList(
  id: (json['id'] as num?)?.toInt(),
  userId: (json['userId'] as num).toInt(),
  itemId: (json['itemId'] as num).toInt(),
  itemType: json['itemType'] as String,
  listType: json['listType'] as String,
);

Map<String, dynamic> _$UserListToJson(UserList instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'itemId': instance.itemId,
  'itemType': instance.itemType,
  'listType': instance.listType,
};
