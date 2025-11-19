import 'package:isar/isar.dart';

part 'channel.g.dart';

@collection
class Channel {
  Id id = Isar.autoIncrement; // Auto-incremented ID for Isar

  @Index(unique: true, replace: true)
  late String name; // Unique name as identifier

  late String logoUrl;
  late String streamUrl;

  Channel({required this.name, required this.logoUrl, required this.streamUrl});

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      name: json['name'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
      streamUrl: json['streamUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'logoUrl': logoUrl, 'streamUrl': streamUrl};
  }
}
