import 'package:get/get.dart';

import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/api_exception.dart';

class AuthController extends GetxController {
  AuthController(this._authService);

  final AuthService _authService;

  final user = Rxn<UserModel>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final rememberMe = true.obs;

  @override
  void onInit() {
    super.onInit();
    user.value = _authService.cachedUser;
  }

  Future<void> checkSession() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await Future<void>.delayed(const Duration(seconds: 3));
      final restored = await _authService.restoreSession();
      if (restored == null) {
        Get.offAllNamed(AppRoutes.login);
      } else {
        user.value = restored;
        Get.offAllNamed(_routeForLayout(restored.layout));
      }
    } catch (_) {
      await _authService.logout();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoading.value = false;
    }
  }

  Future<UserModel?> refreshUser() async {
    if (!_authService.hasToken) return null;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final restored = await _authService.restoreSession();
      user.value = restored;
      return restored;
    } catch (_) {
      await _authService.logout();
      user.value = null;
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  void setRememberMe(bool value) {
    rememberMe.value = value;
  }

  Future<void> login(String email, String password) async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final loggedIn = await _authService.login(
        email: email,
        password: password,
        remember: rememberMe.value,
      );
      user.value = loggedIn;
      Get.offAllNamed(_routeForLayout(loggedIn.layout));
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Dang nhap that bai. Vui long thu lai.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    isLoading.value = true;
    try {
      await _authService.logout();
      user.value = null;
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> switchWorkspace(WorkspaceModel workspace) async {
    final current = user.value;
    if (current == null || workspace.layout.isEmpty) return;

    isLoading.value = true;
    try {
      final updated = await _authService.switchRole(workspace.role);
      user.value = updated;
      Get.offAllNamed(_routeForLayout(updated.layout));
    } finally {
      isLoading.value = false;
    }
  }

  String _routeForLayout(String layout) {
    return switch (layout) {
      'shipper' => AppRoutes.shipperHome,
      'manager_shipper' => AppRoutes.managerShipperHome,
      'warehouse' => AppRoutes.warehouseHome,
      'package' => AppRoutes.packageHome,
      'sale' => AppRoutes.saleHome,
      'accounting' => AppRoutes.accountingHome,
      'ceo' => AppRoutes.ceoHome,
      _ => AppRoutes.unsupported,
    };
  }
}
