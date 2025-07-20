class UserModel {
  final String userId;
  final String name;
  final String phone;

  UserModel({
    required this.userId,
    required this.name,
    required this.phone,
  });

  factory UserModel.fromMap(Map<dynamic, dynamic> map) {
    return UserModel(
      userId: map['userId'],
      name: map['name'],
      phone: map['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
    };
  }
}
