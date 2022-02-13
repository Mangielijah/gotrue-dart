part of netlify_auth;

class RequestOption {
  Map<String, dynamic>? headers;
  final String? audience;
  final String contentType;
  final String body;
  final String method;
  RequestOption({
    Map<String, dynamic>? header,
    this.audience = '',
    this.contentType = 'application/json',
    this.method = 'get',
    this.body = '',
  }) : headers = header ?? {};
}

/// Initializes shared_preference
void sharedPrefInit() async {
  try {
    /// Checks if shared preference exist
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    localStorage = await _prefs;
    localStorage.getString("app-name");
  } catch (err) {
    /// Adds app-name
    SharedPreferences.setMockInitialValues({});
    Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
    localStorage = await _prefs;
    localStorage.setString("app-name", "my-app");
  }
}
