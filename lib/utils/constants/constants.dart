import 'package:vector_academy/flavors/flavor_config.dart';

const authTokenStorage = 'authTokenStorage';
const defaultApiURL = 'https://api.entrancetricks.com';

/// Must match backend `app_package` (e.g. grades, branding). Set per flavor in
/// [FlavorConfig].
String get backendAppPackage => FlavorConfig.backendAppPackage;
// const defaultApiURL = 'http://192.168.1.4:8000';
