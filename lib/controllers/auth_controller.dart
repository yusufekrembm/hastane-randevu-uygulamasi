import 'package:get/get.dart';
import 'package:randevu_al/core/utilities/dialog_helper.dart';
import 'package:randevu_al/models/user_model.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:randevu_al/core/utilities/extensions.dart';
import 'package:randevu_al/services/supabase_auth_service.dart';
import 'package:randevu_al/services/supabase_database_service.dart';
import 'package:randevu_al/views/home_page.dart';

import '../views/login_page.dart';

class AuthController extends GetxController {
  late final SupabaseAuthService _authService = Get.find<SupabaseAuthService>();
  late final SupabaseDatabaseService _dbService =
      Get.find<SupabaseDatabaseService>();
  final Rx<User?> _user = Rx(null);
  User? get user => _user.value;

  bool get isLoggedIn => _user.value != null ? true : false;
  AuthController() {
    currentUser();
  }
  Future<User?> currentUser() async {
    try {
      Get.context?.loaderOverlay.show();
      final supaUser = _authService.currentUser();
      if (supaUser != null) {
        _user.value = await _dbService.getProfile(id: supaUser.id);
        printInfo(info: "AuthController currentUser: ${_user.value?.toMap()}");
        return _user.value;
      }
    } catch (e) {
      Get.context?.loaderOverlay.hide();

      return null;
    } finally {
      Get.context?.loaderOverlay.hide();
    }
    return null;
  }

  Future<User?> login(String mail, String password) async {
    try {
      Get.context?.loaderOverlay.show();
      final supaUser = await _authService.signInWithMailAndPassword(
          mail: mail, password: password);

      if (supaUser != null) {
        _user.value = await _dbService.getProfile(id: supaUser.id);
        return _user.value;
      }
    } catch (e) {
      Get.context?.showErrorDialog(message: "$e");
      return null;
    } finally {
      Get.context?.loaderOverlay.hide();
    }
    return null;
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      _user.value = null;
    } catch (e) {
      DialogHelper.showErrorDialog(
          context: Get.context!, description: e.toString());
    }
  }

  Future<bool> requestPasswordReset(String mail) async {
    if (mail.isEmpty) {
      return false;
    }

    try {
      Get.context?.loaderOverlay.show();
      await _authService.sendPasswordRenewMail(mail);
      return true;
    } catch (e) {
      Get.context?.showErrorDialog(message: "Error: $e");
      return false;
    } finally {
      Get.context?.loaderOverlay.hide();
    }
  }

  Future<dynamic> registerUserWithMailAndPassword({
    required String mail,
    required String password,
    required User user,
  }) async {
    try {
      Get.context?.loaderOverlay.show();
      return await _authService.registerUserWithMailAndPassword(
        mail: mail,
        password: password,
        user: user,
      );
    } catch (e) {
      Get.context?.showErrorDialog(message: "Error: $e");
    } finally {
      Get.context?.loaderOverlay.hide();
    }
  }

  Future<dynamic> redirectUser(User? user) async {
    if (user == null) {
      return Get.offAllNamed(LoginPage.route);
    }

    return Get.offAllNamed(HomePage.route);
  }
}
