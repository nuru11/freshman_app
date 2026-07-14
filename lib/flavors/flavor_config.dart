/// Per-app branding and backend identity. Add a new entry here for each flavor.
class FlavorValues {
  const FlavorValues({
    required this.appTitle,
    required this.backendAppPackage,
    required this.logoAsset,
  });

  final String appTitle;
  final String backendAppPackage;
  final String logoAsset;
}

const _flavorName = String.fromEnvironment(
  'FLAVOR',
  defaultValue: 'freshman',
);

const _flavors = <String, FlavorValues>{
  'freshman': FlavorValues(
    appTitle: 'Freshman',
    backendAppPackage: 'com.freshman_tricks.app',
    logoAsset: 'assets/images/freshmanlogo.png',
  ),
  'vector_academy': FlavorValues(
    appTitle: 'Entrance Tricks',
    backendAppPackage: 'com.vector_academy.app',
    logoAsset: 'assets/images/logo.png',
  ),
  'exitexam': FlavorValues(
    appTitle: 'Ethio Exit Exam',
    backendAppPackage: 'com.ethioexitexam.app',
    logoAsset: 'assets/images/logo_exitexam.png',
  ),
};

/// Active flavor configuration for the current build.
class FlavorConfig {
  FlavorConfig._();

  static final FlavorValues current =
      _flavors[_flavorName] ?? _flavors['freshman']!;

  static String get flavorName => _flavorName;

  static String get appTitle => current.appTitle;

  static String get backendAppPackage => current.backendAppPackage;

  static String get logoAsset => current.logoAsset;
}
