import 'package:json_annotation/json_annotation.dart';

part 'user_list.g.dart';

@JsonSerializable()
class UserList {
  final int? id;
  final int userId;
  final int itemId;
  final String itemType; // 'movie' or 'tv_series'
  final String listType; // 'my_list' or 'favorites'

  UserList({
    this.id,
    required this.userId,
    required this.itemId,
    required this.itemType,
    required this.listType,
  });

  factory UserList.fromJson(Map<String, dynamic> json) =>
      _$UserListFromJson(json);
  Map<String, dynamic> toJson() => _$UserListToJson(this);
}
