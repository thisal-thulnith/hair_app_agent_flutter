class UserModel {
  final int id;
  final String email;
  final String name;
  final String userType; // 'customer' or 'salon_owner'
  final bool ownsSalon;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    required this.ownsSalon,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      userType: json['userType'] as String? ?? 'customer',
      ownsSalon: json['ownsSalon'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'userType': userType,
      'ownsSalon': ownsSalon,
    };
  }

  UserModel copyWith({
    int? id,
    String? email,
    String? name,
    String? userType,
    bool? ownsSalon,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      ownsSalon: ownsSalon ?? this.ownsSalon,
    );
  }
}
