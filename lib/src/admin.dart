part of netlify_auth;

class Admin {
  final User user;
  Admin(this.user);
  // Return a list of all users in an audience
  listUsers(aud) {
    return user.request(
      '/admin/users',
      RequestOption(
        method: 'GET',
        audience: aud,
      ),
    );
  }

  getUser(user) {
    return user.request('/admin/users/${user.id}', RequestOption());
  }

  updateUser(user, {attributes = const {}}) {
    return user.request(
        '/admin/users/${user.id}',
        RequestOption(
          method: 'PUT',
          body: jsonEncode(attributes),
        ));
  }

  createUser(email, password, {attributes = const {}}) {
    attributes.email = email;
    attributes.password = password;
    return user.request(
        '/admin/users',
        RequestOption(
          method: 'POST',
          body: jsonEncode(attributes),
        ));
  }

  deleteUser(user) {
    return user.request(
      '/admin/users/${user.id}',
      RequestOption(
        method: 'DELETE',
      ),
    );
  }
}
