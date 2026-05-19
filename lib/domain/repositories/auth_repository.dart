import 'package:my_accounts/domain/models/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> currentUser();
  Future<AppUser> login(String email, String password);
  Future<AppUser> register(String name, String email, String password);
  Future<void> logout();
  Future<void> markOnboardingSeen();
  Future<bool> isFirstLaunch();
}
