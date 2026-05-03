class UserModel {
  final String username;
  final String fullName;
  final String dob;
  final String shopName;
  final String email;
  final String password;

  UserModel({
    required this.username,
    required this.fullName,
    required this.dob,
    required this.shopName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'fullName': fullName,
      'dob': dob,
      'shopName': shopName,
      'email': email,
      'password': password,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      username: map['username'],
      fullName: map['fullName'],
      dob: map['dob'],
      shopName: map['shopName'],
      email: map['email'],
      password: map['password'],
    );
  }
}
