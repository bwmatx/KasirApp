import '../models/user.dart';

class AuthService {
  static UserModel? currentUser;

  static void login(UserModel user) {
    currentUser = user;
  }

  static void logout() {
    currentUser = null;
  }
}
