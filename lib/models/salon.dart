class Salon {
  final String id;
  final String name;
  final String address;
  final String city;
  final String? state;
  final String country;
  final String? phone;
  final double? rating;
  final int? reviewCount;

  Salon({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.state,
    required this.country,
    this.phone,
    this.rating,
    this.reviewCount,
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['id']?.toString() ?? json['salon_id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['salon_name']?.toString() ?? '',
      address: json['address']?.toString() ?? json['salon_address']?.toString() ?? '',
      city: json['city']?.toString() ?? json['salon_city']?.toString() ?? '',
      state: json['state']?.toString() ?? json['salon_state']?.toString(),
      country: json['country']?.toString() ?? json['salon_country']?.toString() ?? '',
      phone: json['phone']?.toString() ?? json['salon_phone']?.toString(),
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      reviewCount: json['review_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      if (state != null) 'state': state,
      'country': country,
      if (phone != null) 'phone': phone,
      if (rating != null) 'rating': rating,
      if (reviewCount != null) 'review_count': reviewCount,
    };
  }

  String get fullAddress {
    final parts = [address, city];
    if (state != null && state!.isNotEmpty) parts.add(state!);
    parts.add(country);
    return parts.join(', ');
  }
}
