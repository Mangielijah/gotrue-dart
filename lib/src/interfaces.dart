part of netlify_auth;

abstract class UserData {
  dynamic app_metadata;
  String? aud;
  String? audience;
  String? confirmed_at;
  String? created_at;
  String? email;
  String? id;
  String? role;
  Token? token;
  String? updated_at;
  String? url;
  dynamic user_metadata;
  void clearSession();
  Future<UserData> getUserData();
  Future<String> jwt({bool forceRefresh = false});
  Future<void> logout();
  Token tokenDetails();
  Future<User> update(dynamic attribute);
}

class Token {
  String? access_token;
  num? expires_at;
  num? expires_in;
  String? refresh_token;
  String? token_type;
  Token({
    required this.access_token,
    this.expires_at,
    required this.expires_in,
    required this.refresh_token,
    this.token_type = 'bearer',
  });
  Token.fromJson(Map<String, dynamic> json) {
    token_type = json['token_type'] ?? 'bearer';
    access_token = json['access_token'];
    expires_in = json['expires_in'];
    expires_at = json['expires_at'];
    refresh_token = json['refresh_token'];
  }
  Map<String, dynamic> toJson() {
    return {
      'token_type': token_type,
      'access_token': access_token,
      'expires_in': expires_in,
      'expires_at': expires_at,
      'refresh_token': refresh_token,
    };
  }
}

abstract class Settings {
  bool? autoconfirm;
  late bool disable_signup;
  Map external = {
    'bitbucket': false,
    'email': false,
    'facebook': false,
    'github': false,
    'gitlab': false,
    'google': false,
  };
}

class GoTrueInit {
  final String APIUrl;
  final String? audience;
  final bool? setCookie;
  GoTrueInit({
    required this.APIUrl,
    this.audience = '',
    this.setCookie = false,
  });
}
