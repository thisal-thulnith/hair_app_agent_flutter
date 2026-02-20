class Product {
  final String id;
  final String name;
  final String sku;
  final String? description;
  final String category;
  final int quantity;
  final int minQuantity;
  final double unitPrice;
  final bool isLowStock;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.description,
    required this.category,
    required this.quantity,
    required this.minQuantity,
    required this.unitPrice,
    required this.isLowStock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity'] as int? ?? 0;
    final minQuantity = json['min_quantity'] as int? ?? json['minQuantity'] as int? ?? 10;

    return Product(
      id: json['id']?.toString() ?? json['product_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? 'general',
      quantity: quantity,
      minQuantity: minQuantity,
      unitPrice: (json['unit_price'] ?? json['unitPrice'] ?? 0.0) is int
          ? (json['unit_price'] ?? json['unitPrice'] ?? 0).toDouble()
          : (json['unit_price'] ?? json['unitPrice'] ?? 0.0) as double,
      isLowStock: quantity < minQuantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      if (description != null) 'description': description,
      'category': category,
      'quantity': quantity,
      'min_quantity': minQuantity,
      'unit_price': unitPrice,
    };
  }

  String get stockStatus {
    if (quantity == 0) return 'Out of Stock';
    if (isLowStock) return 'Low Stock';
    return 'In Stock';
  }

  String get formattedPrice {
    return '\$${unitPrice.toStringAsFixed(2)}';
  }
}
