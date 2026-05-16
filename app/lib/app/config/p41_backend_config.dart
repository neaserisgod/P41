class P41BackendConfig {
  const P41BackendConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'P41_API_BASE_URL',
    defaultValue: 'http://31.97.166.250',
  );
}
