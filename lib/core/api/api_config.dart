class ApiConfig {
  static const isPreview = bool.fromEnvironment('APP_PREVIEW');
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const apiPrefix = '/api/v1';

  static String get apiBase => '$baseUrl$apiPrefix';
}
