part of netlify_auth;

const ExpiryMargin = 60 * 1000;
const storageKey = 'gotrue.user';
const refreshPromises = {};
User? currentUser;
const forbiddenUpdateAttributes = {
  'api': 1,
  'token': 1,
  'audience': 1,
  'url': 1
};
const forbiddenSaveAttributes = {
  'api': 1,
  'fromStorage': 1,
};
const bool isBrowser = true;

class User implements UserData {
  late Dio api;
  @override
  String? audience;

  @override
  String? aud;

  @override
  String? confirmed_at;

  @override
  String? created_at;

  @override
  String? email;

  @override
  String? id;

  @override
  String? role;

  @override
  Token? token;

  @override
  String? updated_at;

  @override
  dynamic user_metadata;

  @override
  dynamic app_metadata;

  @override
  String? url;

  bool? fromStorage;

  User({required this.api, required dynamic tokenResponse, String aud = ''}) {
    url = api.options.baseUrl;
    audience = aud;
    _processTokenResponse(tokenResponse);
    currentUser = this;
  }

  static List props = [
    'api',
    'audience',
    'app_metadata',
    'aud',
    'confirmed',
    'created_at',
    'email',
    'id',
    'token',
    'updated_at',
    'user_metadata',
    'url',
  ];

  User.fromUser(User user) {
    api = api;

    audience = audience;

    app_metadata = app_metadata;

    aud = aud;

    confirmed_at = confirmed_at;

    created_at = created_at;

    email = email;

    id = id;

    role = role;

    token = token;

    updated_at = updated_at;

    user_metadata = user_metadata;

    url = url;

    fromStorage = fromStorage;
  }
  copy(User user) {
    api = user.api;

    audience = user.audience;

    app_metadata = user.app_metadata;

    aud = user.aud;

    confirmed_at = user.confirmed_at;

    created_at = user.created_at;

    email = user.email;

    id = user.id;

    role = user.role;

    token = user.token;

    updated_at = user.updated_at;

    user_metadata = user.user_metadata;

    url = user.url;

    fromStorage = user.fromStorage;
  }

  User.fromJson(Map<String, dynamic> json) {
    api = json['api'];

    audience = json['aud'];

    app_metadata = json['app_metadata'];

    aud = json['aud'];
    if (json['confirmed_at'] != null) confirmed_at = json['confirmed_at'];

    created_at = json['created_at'];

    email = json['email'];

    id = json['id'];

    role = json['role'];
    if (json['token'] != null) token = json['token'];

    updated_at = json['updated_at'];

    user_metadata = json['user_metadata'];

    url = json['url'];
  }

  Map<String, dynamic> toJson() {
    return {
      'api': {
        'apiURL': api.options.baseUrl,
        '_sameOrigin': true,
        'defaultHeaders': {},
      },
      'audience': audience,
      'app_metadata': app_metadata,
      'confirmed_at': confirmed_at,
      'created_at': created_at,
      'email': email,
      'id': id,
      'role': role,
      'token': token!.toJson(),
      'updated_at': updated_at,
      'user_metadata': user_metadata,
      'url': url,
    };
  }

  bool get isConfirmed => (() {
        try {
          if (confirmed_at is String) {
            return true;
          } else {
            return false;
          }
        } catch (e) {
          return false;
        }
      })();

  static void removeSavedSession() async {
    isBrowser && await localStorage.remove(storageKey);
  }

  static User? recoverSession(apiInstance) {
    if (currentUser != null) {
      return currentUser;
    }

    final json = localStorage.getString(storageKey);
    if (isBrowser && json != null) {
      try {
        final data = jsonDecode(json);
        final url = data['url'];
        final token = data['token'];
        final audience = data['audience'];
        if (!url || !token) {
          return null;
        }

        final api = apiInstance ??
            Dio(
              url,
            );
        return User(api: api, tokenResponse: token, aud: audience)
            ._saveUserData(attributes: data, fromStorage: true);
      } catch (error) {
        debugPrint('Gotrue-js: Error recovering session: $error');
        return null;
      }
    }

    return null;
  }

  get admin => Admin(this);

  @override
  Future<User> update(attributes) async {
    Response res = await request(
        '/user',
        RequestOption(
          method: 'PUT',
          body: json.encode(attributes),
        ));
    return _saveUserData(attributes: res.data)._refreshSavedSession();
  }

  @override
  Future<String> jwt({bool forceRefresh = false}) {
    Token token = tokenDetails();
    if (token == null) {
      debugPrint('Gotrue-js: failed getting jwt access token');
      return Future.error(Error());
    }
    final num expires_at = token.expires_at!;
    final refresh_token = token.refresh_token;
    final access_token = token.access_token;
    if (forceRefresh ||
        DateTime.now().isAfter(DateTime.fromMillisecondsSinceEpoch(
            expires_at.toInt() - ExpiryMargin))) {
      return _refreshToken(refresh_token!);
    }
    return Future.value(access_token);
  }

  @override
  Future<void> logout() {
    return request(
            '/logout',
            RequestOption(
              method: 'POST',
            ))
        .then((value) => clearSession())
        .catchError((onError) => clearSession());
  }

  _refreshToken(String refresh_token) {
    if (refreshPromises[refresh_token] != null) {
      return refreshPromises[refresh_token];
    }
    return (refreshPromises[refresh_token] = api
        .request(
      '/token',
      data: 'grant_type=refresh_token&refresh_token=$refresh_token',
      options: Options(
          method: 'POST', contentType: 'application/x-www-form-urlencoded'),
    )
        .then((response) {
      refreshPromises.remove(refresh_token);
      _processTokenResponse(response);
      _refreshSavedSession();
      return token!.access_token;
    }).catchError(
      (error) {
        refreshPromises.remove(refresh_token);
        clearSession();
      },
    ));
  }

  Future<Response> request(path, RequestOption options) async {
    final aud = options.audience ?? audience;
    if (aud != null) {
      options.headers!['X-JWT-AUD'] = aud;
    }

    try {
      final token = await jwt();
      return api.request(
        path,
        data: options.body,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            ...options.headers ?? {},
          },
          contentType: options.contentType,
          method: options.method,
        ),
      );
    } on DioError catch (e) {
      debugPrint(e.toString());
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

  @override
  Future<User> getUserData() async {
    Response res = await request('/user', RequestOption());
    // .then(_saveUserData.bind(this))
    _saveUserData(
      attributes: res.data,
    );
    // .then(_refreshSavedSession.bind(this));
    return _refreshSavedSession();
  }

  User _saveUserData({required Map attributes, fromStorage = false}) {
    for (final key in attributes.keys) {
      if ((User.props.contains(key)) &&
          forbiddenUpdateAttributes.keys.contains(key)) {
        continue;
      }
      _saveKeyValue(key, attributes);
    }
    if (fromStorage) {
      this.fromStorage = true;
    }
    return this;
  }

  _saveKeyValue(String key, Map<dynamic, dynamic> json) {
    switch (key) {
      case 'api':
        api = json['api'];
        break;
      case 'audience':
        audience = json['aud'];
        break;
      case 'app_metadata':
        app_metadata = json['app_metadata'];
        break;
      case 'confirmed_at':
        aud = json['aud'];
        if (json['confirmed_at'] != null) confirmed_at = json['confirmed_at'];
        break;
      case 'created_at':
        created_at = json['created_at'];
        break;
      case 'email':
        email = json['email'];
        break;
      case 'id':
        id = json['id'];
        break;
      case 'token':
        role = json['role'];
        if (json['token'] != null) token = json['token'];
        break;
      case 'updated_at':
        updated_at = json['updated_at'];
        break;
      case 'user_metadata':
        user_metadata = json['user_metadata'];
        break;
      case 'url':
        url = json['url'];
        break;
    }
  }

  _processTokenResponse(tokenResponse) {
    Map<String, dynamic> tokenData = tokenResponse.data;
    token = Token(
      access_token: tokenData['access_token'],
      expires_in: tokenData['expires_in'],
      refresh_token: tokenData['refresh_token'],
    );

    try {
      final res = urlBase64Decode(token!.access_token!.split('.')[1]);
      final claims = json.decode(res);
      token!.expires_at = claims['exp'] * 1000;
    } catch (error) {
      // console.error(new Error(`Gotrue-js: Failed to parse tokenResponse claims: ${error}`));
      debugPrint('Gotrue-js: Failed to parse tokenResponse claims: $error');
    }
  }

  User _refreshSavedSession() {
    // only update saved session if we previously saved something
    if (isBrowser) {
      localStorage.get(storageKey);
      saveSession();
    }
    return this;
  }

  get _details => (() {
        final userCopy = {};
        final thisJson = toJson();
        for (final key in thisJson.keys) {
          if (User.props.contains(key) &&
              forbiddenSaveAttributes.keys.contains(key)) {
            continue;
          }
          userCopy[key] = thisJson[key];
        }
        return userCopy;
      })();

  saveSession() async {
    isBrowser &&
        await localStorage.setString(storageKey, json.encode(_details));
    return this;
  }

  @override
  Token tokenDetails() {
    return token!;
  }

  @override
  void clearSession() {
    User.removeSavedSession();
    token = null;
    currentUser = null;
  }
}

String urlBase64Decode(String str) {
  // From https://jwt.io/js/jwt.js
  String output = str.replaceAll(r'/-/g', '+').replaceAll(r'/_/g', '/');
  switch (output.length % 4) {
    case 0:
      break;
    case 2:
      output += '==';
      break;
    case 3:
      output += '=';
      break;
    default:
      throw 'Illegal base64url string!';
  }

  // polifyll https://github.com/davidchambers/Base64.js
  final result = base64Decode(output);
  try {
    return Uri.decodeComponent(utf8.decode(result));
  } catch (e) {
    return String.fromCharCodes(result);
  }
}
