// lib/models/user.dart
class User {
  final String customerId;
  final String name;
  final String email;

  User({required this.customerId, required this.name, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      customerId: json['customer_id'],
      name: json['name'],
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
    'customer_id': customerId,
    'name': name,
    'email': email,
  };
}