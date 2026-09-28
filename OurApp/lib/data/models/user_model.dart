class UserModel {
  final String id;
  final String email;
  final String role;
  final bool emailVerified;
  final bool mustChangePassword;
  final String profileCreatedFor;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.emailVerified,
    this.mustChangePassword = false,
    required this.profileCreatedFor,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      emailVerified: json['emailVerified'] ?? false,
      mustChangePassword: json['mustChangePassword'] ?? false,
      profileCreatedFor: json['profileCreatedFor'] ?? 'self',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'emailVerified': emailVerified,
      'mustChangePassword': mustChangePassword,
      'profileCreatedFor': profileCreatedFor,
    };
  }

  bool get isAdmin => role == 'admin';
}
