# Multi-app flavors

This repo builds multiple store apps from one codebase using Flutter flavors.

## Current flavors

| Flavor | App name | Android package | iOS bundle ID |
|--------|----------|-----------------|---------------|
| `vector_academy` | Entrance Tricks | `com.vector_academy.app` | `com.vectoracademy.app` |
| `exitexam` | Ethio Exit Exam | `com.ethioexitexam.app` | `com.ethioexitexam.app` |

## Run / build

```powershell
# Run
.\scripts\run.ps1 exitexam
.\scripts\run.ps1 vector_academy

# Release builds
.\scripts\build.ps1 exitexam appbundle
.\scripts\build.ps1 vector_academy apk
```

Or directly:

```bash
flutter run --flavor exitexam --dart-define=FLAVOR=exitexam
flutter build appbundle --flavor exitexam --dart-define=FLAVOR=exitexam
```

## Android signing

1. Copy `android/key_exitexam.properties.example` to `android/key_exitexam.properties`
2. Fill in keystore credentials
3. Place `upload-keystore_exitexam.jks` in `android/app/`

Existing `android/key.properties` is used for `vector_academy`.

## Add a new app (checklist)

1. Add `assets/images/logo_<flavor>.png`
2. Add an entry in `lib/flavors/flavor_config.dart`
3. Add Android `productFlavor` in `android/app/build.gradle.kts` + keystore properties
4. Add iOS xcconfig files in `ios/Flutter/` and Xcode build configurations
5. Add `flutter_launcher_icons-<flavor>.yaml` and run:
   `dart run flutter_launcher_icons -f flutter_launcher_icons-<flavor>.yaml`
6. Create Xcode scheme `<flavor>.xcscheme`
7. Register `app_package` on the backend API
8. Add launch config in `.vscode/launch.json`
