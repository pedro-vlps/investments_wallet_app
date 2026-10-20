abstract interface class QuoteCredentials {
  Future<String?> readAccessToken();
  Future<void> saveAccessToken(String token);
  Future<void> deleteAccessToken();
}

class QuoteCredentialException implements Exception {
  const QuoteCredentialException(this.message);
  final String message;
  @override
  String toString() => message;
}

String validateQuoteAccessToken(String value) {
  final token = value.trim();
  if (!RegExp(r'^[!-~]{1,4096}$').hasMatch(token)) {
    throw const QuoteCredentialException(
      'Informe uma chave válida, sem espaços ou quebras de linha.',
    );
  }
  return token;
}
