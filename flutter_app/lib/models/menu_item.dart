class MenuItem {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;
  final String description;
  final bool available;
  final int prepMinutes;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    this.category = 'Main',
    this.imageUrl,
    this.description = '',
    this.available = true,
    this.prepMinutes = 10,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
        id: json['id'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        category: json['category'] ?? 'Main',
        imageUrl: json['imageUrl'],
        description: json['description'] ?? '',
        available: json['available'] ?? true,
        prepMinutes: json['prepMinutes'] ?? 10,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'imageUrl': imageUrl,
        'description': description,
        'available': available,
        'prepMinutes': prepMinutes,
      };

  MenuItem copyWith({bool? available}) => MenuItem(
        id: id,
        name: name,
        price: price,
        category: category,
        imageUrl: imageUrl,
        description: description,
        available: available ?? this.available,
        prepMinutes: prepMinutes,
      );
}
