class Channel {
  final int id;
  final String name;
  final String logoPath;
  final String streamUrl;
  final String category;
  final String description;
  final String imageUrls;

  Channel({
    required this.id,
    required this.name,
    required this.logoPath,
    required this.streamUrl,
    required this.category,
    required this.description,
    required this.imageUrls,
  });

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      logoPath: json['logopath'] ?? json['logoPath'] ?? json['logo_path'] ?? '',
      streamUrl:
          json['streamurl'] ?? json['streamUrl'] ?? json['stream_url'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      imageUrls: json['imageurls'] ?? json['imageUrls'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoPath': logoPath,
      'streamUrl': streamUrl,
      'category': category,
      'description': description,
      'imageUrls': imageUrls,
    };
  }

  Map<String, dynamic> toMap() {
    return toJson();
  }

  factory Channel.fromMap(Map<String, dynamic> map) {
    return Channel(
      id: map['id'] ?? 0,
      name: map['name'] ?? '',
      logoPath: map['logoPath'] ?? '',
      streamUrl: map['streamUrl'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      imageUrls: map['imageUrls'] ?? '',
    );
  }
}
