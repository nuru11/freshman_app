import 'package:vector_academy/models/models.dart';
import 'package:vector_academy/services/api/api.dart';
import 'package:vector_academy/utils/storages/storages.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  final HiveAuthStorage _hiveAuthStorage = HiveAuthStorage();
  final HiveUserStorage _hiveUserStorage = HiveUserStorage();

  Rx<AuthToken?> authToken = Rx<AuthToken?>(null);
  Rx<User?> user = Rx<User?>(null);

  @override
  Future<void> onInit() async {
    await loadUser();
    super.onInit();
  }

  Future<void> saveAuthToken(AuthToken authToken) async {
    await _hiveAuthStorage.setAuthToken(authToken);
    BaseApiClient.setTokens(authToken.access, authToken.refresh);
    this.authToken.value = authToken;
  }

  Future<void> saveUser(User user) async {
    this.user.value = user;
    await _hiveUserStorage.setUser(user);
  }

  Future<void> loadUser() async {
    authToken.value = await _hiveAuthStorage.getAuthToken();
    user.value = await _hiveUserStorage.getUser();
    BaseApiClient.setTokens(
      authToken.value?.access ?? '',
      authToken.value?.refresh ?? '',
    );
  }

  Future<void> logout() async {
    await _hiveAuthStorage.clear();
    await _hiveUserStorage.clear();
    authToken.value = null;
    user.value = null;
  }

  void listenToken(void Function(AuthToken?) callback) {
    _hiveAuthStorage.listen(callback, 'authToken');
  }

  void listenUser(void Function(User?) callback) {
    _hiveUserStorage.listen(callback, 'user');
  }
}
