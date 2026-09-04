class UserModel {
  final String customUserId;
  final String email;
  final String roleCode;
  final String? token;
  final bool? isEmailVerified;

  UserModel({
    required this.customUserId,
    required this.email,
    required this.roleCode,
    this.token,
    this.isEmailVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      customUserId: json['customUserId']?.toString() ?? '',
      email: json['email'] ?? '',
      roleCode: json['roleCode'] ?? '',
      token: json['token'],
      isEmailVerified: json['isEmailVerified'],
    );
  }
}