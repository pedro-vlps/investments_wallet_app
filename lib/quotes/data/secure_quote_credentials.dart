import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/quote_credentials.dart';

class SecureQuoteCredentials implements QuoteCredentials {
  const SecureQuoteCredentials();
  // Direct macOS distribution does not require shared keychain entitlements.
  static const _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );
  static const _key = 'investments_wallet.brapi_api_token';

  @override
  Future<String?> readAccessToken() async {
    try {
      final token = await _storage.read(key: _key);
      return token == null ? null : validateQuoteAccessToken(token);
    } catch (_) {
      throw const QuoteCredentialException(
        'Não foi possível ler a chave no armazenamento seguro. Abra a configuração de cotações.',
      );
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    final validated = validateQuoteAccessToken(token);
    try {
      await _storage.write(key: _key, value: validated);
      if (await _storage.read(key: _key) != validated) {
        throw const QuoteCredentialException(
          'A gravação da chave não pôde ser confirmada.',
        );
      }
    } catch (_) {
      throw const QuoteCredentialException(
        'Não foi possível salvar a chave no armazenamento seguro deste dispositivo.',
      );
    }
  }

  @override
  Future<void> deleteAccessToken() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      throw const QuoteCredentialException(
        'Não foi possível remover a chave do armazenamento seguro.',
      );
    }
  }
}
