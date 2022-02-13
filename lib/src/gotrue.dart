part of netlify_auth;

RegExp HTTPRegexp = RegExp(
  r'/^http:\/\//',
  caseSensitive: false,
);
RegExp ORIGINRegexp = RegExp(r'/\/[^\/]?/');
const defaultApiURL = '/.netlify/identity';

abstract class GoTrueExternalProvider {
  static const String email = 'email';
  static const String google = 'google';
  static const String github = 'github';
  static const String bitbucket = 'bitbucket';
  static const String gitlab = 'gitlab';
  static const String facebook = 'facebook';
}

class GoTrue {
  late String APIUrl;
  late String? audience;
  late bool? setCookie;
  late Dio api;
  late bool _sameOrigin;
  GoTrue(GoTrueInit init) {
    if (HTTPRegexp.hasMatch(init.APIUrl)) {
      debugPrint(
        'Warning:\n\nDO NOT USE HTTP IN PRODUCTION FOR GOTRUE EVER!\nGoTrue REQUIRES HTTPS to work securely.',
      );
    }
    APIUrl = init.APIUrl;

    if (init.audience != null) {
      audience = init.audience;
    }

    if (ORIGINRegexp.hasMatch(APIUrl)) {
      // eslint-disable-line no-useless-escape
      _sameOrigin = true;
    }

    setCookie = init.setCookie;

    api = Dio(BaseOptions(
      baseUrl: APIUrl,
    ));
  }

  Future<Response> _request(
    String path,
    RequestOption options,
  ) async {
    final String aud = options.audience ?? audience!;
    options.headers!['X-JWT-AUD'] = aud;
    try {
      return api.request(
        path,
        data: options.body,
        options: Options(
          headers: options.headers,
          contentType: options.contentType,
          method: options.method,
        ),
      );
    } on DioError catch (e) {
      debugPrintStack();
      if (e.response!.statusCode == 404) {
        debugPrint(e.response!.statusCode.toString());
      } else {
        debugPrint(e.message);
        debugPrint(e.requestOptions.toString());
      }
      rethrow;
    }
  }

  settings() {
    return _request('/settings', RequestOption());
  }

  Future<User> signup(email, password, {data}) async {
    Response res = await _request(
      '/signup',
      RequestOption(
        method: 'POST',
        body: json.encode({
          'email': email,
          'password': password,
          if (data != null) 'data': data
        }),
      ),
    );
    Map<String, dynamic> jsonRes = {
      ...res.data,
      'api': api,
      'url': api.options.baseUrl
    };
    return User.fromJson(jsonRes);
  }

  Future<User> login(String email, String password,
      {bool remember = false}) async {
    _setRememberHeaders(remember);
    Response res = await _request(
      '/token',
      RequestOption(
        method: 'POST',
        header: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: '''grant_type=password&username=${Uri.encodeComponent(
          email,
        )}&password=${Uri.encodeComponent(password)}''',
      ),
    );
    User.removeSavedSession();
    return createUser(res, remember: remember);
  }

  String loginExternalUrl(String provider) {
    return '${api.options.baseUrl}/authorize?provider=$provider';
  }

  Future<User> confirm(String link, bool? remember) async {
    _setRememberHeaders(remember);
    String token = link.split('confirmation_token=')[1];
    return verify('signup', token, remember: remember);
  }

  Future<void> requestPasswordRecovery(String email) {
    return _request(
      '/recover',
      RequestOption(
        method: 'POST',
        body: json.encode({'email': email}),
      ),
    );
  }

  Future<User> recover(String link, {bool? remember = false}) async {
    _setRememberHeaders(remember);
    String token = link.split('recovery_token=')[1];
    return verify('recovery', token, remember: remember);
  }

  Future<User> acceptInvite(
      String token, String password, bool? remember) async {
    _setRememberHeaders(remember);
    Response res = await _request(
        '/verify',
        RequestOption(
          method: 'POST',
          body: json
              .encode({'token': token, 'password': password, 'type': 'signup'}),
        ));

    return createUser(res, remember: remember!);
  }

  acceptInviteExternalUrl(provider, token) {
    return '${api.options.baseUrl}/authorize?provider=$provider&invite_token=$token';
  }

  Future<User> createUser(dynamic tokenResponse, {bool remember = false}) {
    _setRememberHeaders(remember);
    final user = User(api: api, tokenResponse: tokenResponse, aud: audience!);
    return user.getUserData().then((userData) {
      if (remember) {
        userData.saveSession();
      }
      return userData;
    });
  }

  User? currentUser() {
    final user = User.recoverSession(api);
    if (user != null) _setRememberHeaders(user.fromStorage ?? false);
    return user;
  }

  Future<User> verify(String type, String token,
      {bool? remember = false}) async {
    _setRememberHeaders(remember);
    Response res = await _request(
        '/verify',
        RequestOption(
          method: 'POST',
          body: json.encode({'token': token, 'type': type}),
        ));
    return createUser(res, remember: remember!);
  }

  void _setRememberHeaders(remember) {
    if (setCookie!) {
      api.options.headers = api.options.headers;
      api.options.headers['X-Use-Cookie'] = remember ? '1' : 'session';
    }
  }
}
