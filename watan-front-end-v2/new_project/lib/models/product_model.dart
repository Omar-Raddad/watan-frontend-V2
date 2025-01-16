class Product {
  final String id;
  final String name;
  final String description;
  final double? price;
  final bool occasion;
  final String ownerId;
  final List<String> images;
  final String categoryName;

  // Sponsorship fields
  final bool isSponsored;
  final double? amountPaid;
  final int? priority;
  final List<String>? targetLocations; // List of city names
  final bool nationwide;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.price,
    required this.occasion,
    required this.ownerId,
    required this.images,
    required this.categoryName,
    required this.isSponsored,
    this.amountPaid,
    this.priority,
    this.targetLocations,
    required this.nationwide,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final sponsorship = json['sponsorship'] ?? {};

    return Product(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      ownerId: json['user']?['_id'] ?? '', // Handle nested user field
      price: json['price'] != null ? json['price'].toDouble() : null,
      occasion: json['occasion'] ?? false,
      images: List<String>.from(json['images'] ?? []),
      categoryName:
          json['category']?['name'] ?? 'Unknown', // Handle missing category
      isSponsored: sponsorship['isSponsored'] ?? false,
      amountPaid: sponsorship['amountPaid'] != null
          ? sponsorship['amountPaid'].toDouble()
          : null,
      priority: sponsorship['priority'] ?? 0,
      targetLocations: sponsorship['targetLocations'] != null
          ? List<String>.from(
              (sponsorship['targetLocations'] as List)
                  .map((loc) => loc['city']),
            )
          : null,
      nationwide: sponsorship['nationwide'] ?? false,
    );
  }
}
