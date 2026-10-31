# Legacy secure-storage compatibility

Source: flutter_secure_storage 9.2.4, https://github.com/juliansteenbak/flutter_secure_storage
License: MIT, retained in LICENSE.

FlutterSecureStorage.java and its ciphers/ package are included in native/app/src/main/java/com/it_nomads/fluttersecurestorage without a Flutter engine. The native AccountStore reads the same sessionZF encrypted record and Android Keystore keys as v0.19.77, preserving encrypted-account compatibility. androidx.security:security-crypto retains the version used by the plugin. No account values are copied into the repository.
