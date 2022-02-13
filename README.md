# gotrue-dart library


This is a Dart client library for the [GoTrue](https://github.com/netlify/gotrue) API.

It lets you create and authenticate users and is a building block for constructing
the UI for signups, password recovery, login and logout.

Play around the methods via the [demo site](https://gotruedart-playground.netlify.com/).

## Installation

To use this plugin, add netlify_auth as a dependency in your pubspec.yaml file.
```js
$ flutter pub add netlify_auth
```

## Usage

```js
import 'package:netlify_auth/netlify_auth.dart';

// Instantiate the GoTrue auth client with a GoTrueInit configuration

GoTrue auth = GoTrue(
  GoTrueInit(
    APIUrl: 'https://brave-colden-1959c1.netlify.app/.netlify/identity',
    setCookie: true,
  ),
);
```

### GoTrue configuration

APIUrl: The absolute path of the GoTrue endpoint. To find the `APIUrl`, go to `Identity` page of your Netlify site dashboard.

audience(optional): `audience` is one of the pre-defined [JWT payload](https://tools.ietf.org/html/rfc7519#section-4.1.3) claims. It's an optional attribute which is set to be empty by default. If you were hosting your own identity service and wanted to support [multitenancy](https://en.wikipedia.org/wiki/Multitenancy), you would need `audience` to separate the users.

setCookie(optional): set to be `false` by default. If you wish to implement the `remember me` functionality, set the value to be `true`.

## Authentication examples

### Create a new user

Create a new user with the specified email and password

```js
auth.signup(email, password);
```

Example usage:

```js
auth
  .signup(email, password)
  .then(response => debugPrint("Confirmation email sent"))
  .catchError(error => debugPrint("It's an error"));
```

Example response object:

```js
User (
  id: 'example-id',
  aud: '',
  role: '',
  email: 'example@example.com',
  confirmation_sent_at: '2018-04-27T22:36:59.636416916Z',
  app_metadata: { provider: 'email' },
  user_metadata: null,
  created_at: '2018-04-27T22:36:59.632133283Z',
  updated_at: '2018-04-27T22:37:00.061039863Z'
)
```

Also, make sure the `Registration preferences` under `Identity settings` in your Netlify dashboard are set to `Open`.

![registration preferences](src/images/identity-settings-registration.png)

If the registration preferences is set to be `Invite only`, you'll get an error message like this:
`{code: 403, msg: 'Signups not allowed for this instance'}`

### Confirm a new user signup

This function confirms a user sign up via a unique confirmation token

```js
auth.confirm(confirmationLink);
```

When a new user signed up, a confirmation email will be sent to the user if `Autoconfirm` isn't turned on under the [identity settings](https://www.netlify.com/docs/identity/#adding-users).

In the email, there's a link that says "Confirm your email address".
When a user clicks on the link, it'll be redirected to the site with a [fragment identifier](https://en.wikipedia.org/wiki/Fragment_identifier) `#confirmation_token=Iyo9xHvsGVbW-9A9v4sDmQ` in the URL.


If you wish to confirm a user use the `auth.confirm(confirmationLink)`.

Example usage:

```js
auth
  .confirm(confirmationLink)
  .then((response) {
    debugPrint("Confirmation email sent"));
  })
  .catchError((e) {
    debugPrint(e.toString());
  });
```

### Check confirmed user

This function returns a boolean when call of the users status


```js
user.isConfirmed
```

Example usage:

```js
if (user.isConfirmed) {
    Navigator.push(context,
        MaterialPageRoute(
            builder: (context) => const Dashboard()));
} else {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => const ConfirmationPage()));
}
```


### Login a user

Handles user login via the specified email and password

`auth.login(email, password)`

Example usage:

```js
auth
  .login(email.value, password.value)
  .then(response => showMessage("Success! Response: " , form))
  .catchError(error => showMessage("Failed"));
```

Example response object:

```js
User(
    api: {
      "apiURL": "https://example.netlify.com/.netlify/identity",
      "_sameOrigin": true,
      "defaultHeaders": {}
    },
    url: "https://example.netlify.com/.netlify/identity",
    toke: Token(
      access_token: "example-jwt-token",
      token_type: "bearer",
      expires_in: 3600,
      refresh_token: "example-refresh_token",
      expires_at: 1526062471000
    ),
    id: "example-id",
    aud: "",
    role: "",
    email: "example@netlify.com",
    confirmed_at: "2018-05-04T23:57:17Z",
    app_metadata: {
      "provider": "email"
    },
    user_metadata: {},
    created_at: "2018-05-04T23:57:17Z",
    updated_at: "2018-05-04T23:57:17Z"
  
)
```

### Request password recover email

This function sends a request to GoTrue API and triggers a password recovery email to the specified email address.
Similar to `confirmation_token`, the `recovery_token` is baked in the link of the email. You can also copy the link location from the email and run `curl -I` in the command line to grab the token.

`auth.requestPasswordRecovery(email)`

Example usage:

```js
auth
  .requestPasswordRecovery(email)
  .then(response => debugPrint("Recovery email sent"))
  .catchError(error => debugPrint("Error sending recovery mail"));
```

Example response object:
`{}`

### Recover a user account

This function recovers a user account via a recovery token

`auth.recover(recoveryLink)`

Example usage:

```js
auth
  .recover(recoveryLink)
  .then(response =>
    debugPrint("Logged in as %s")
  )
  .catchError(error => debugPrint("Failed to verify recovery token"));
```

Example response object:

```js
User(
    api: {
      "apiURL": "https://example.netlify.com/.netlify/identity",
      "_sameOrigin": true,
      "defaultHeaders": {}
    },
    url: "https://example.netlify.com/.netlify/identity",
    toke: Token(
      access_token: "example-jwt-token",
      token_type: "bearer",
      expires_in: 3600,
      refresh_token: "example-refresh_token",
      expires_at: 1526062471000
    ),
    id: "example-id",
    aud: "",
    role: "",
    email: "example@netlify.com",
    confirmed_at: "2018-05-04T23:57:17Z",
    app_metadata: {
      "provider": "email"
    },
    user_metadata: {},
    created_at: "2018-05-04T23:57:17Z",
    updated_at: "2018-05-04T23:57:17Z"
  
)
```

### Get current user

This function returns the current user object when a user is logged in

`auth.currentUser()`

Example usage:

```js
final user = auth.currentUser();
```

Example response object:

```js
User(
    api: {
      "apiURL": "https://example.netlify.com/.netlify/identity",
      "_sameOrigin": true,
      "defaultHeaders": {}
    },
    url: "https://example.netlify.com/.netlify/identity",
    toke: Token(
      access_token: "example-jwt-token",
      token_type: "bearer",
      expires_in: 3600,
      refresh_token: "example-refresh_token",
      expires_at: 1526062471000
    ),
    id: "example-id",
    aud: "",
    role: "",
    email: "example@netlify.com",
    confirmed_at: "2018-05-04T23:57:17Z",
    app_metadata: {
      "provider": "email"
    },
    user_metadata: {},
    created_at: "2018-05-04T23:57:17Z",
    updated_at: "2018-05-04T23:57:17Z"
)
```

### Update a user

This function updates a user object with specified attributes

`user.update( attributes )`

Example usage:

```js
const user = auth.currentUser();

user
  .update({ email: "example@example.com", password: "password" })
  .then(user => debugPrint("Updated user"))
  .catchError((error) {
    debugPrint("Failed to update user");
    rethrow;
  );
```

Example response object:

```js
User(
    api: {
      "apiURL": "https://example.netlify.com/.netlify/identity",
      "_sameOrigin": true,
      "defaultHeaders": {}
    },
    url: "https://example.netlify.com/.netlify/identity",
    toke: Token(
      access_token: "example-jwt-token",
      token_type: "bearer",
      expires_in: 3600,
      refresh_token: "example-refresh_token",
      expires_at: 1526062471000
    ),
    id: "example-id",
    aud: "",
    role: "",
    email: "example@netlify.com",
    confirmed_at: "2018-05-04T23:57:17Z",
    app_metadata: {
      "provider": "email"
    },
    user_metadata: {},
    created_at: "2018-05-04T23:57:17Z",
    updated_at: "2018-05-04T23:57:17Z"
  
)
```

### Get a JWT token

This function retrieves a JWT token from a currently logged in user

`user.jwt()`

Example usage:

```js
const user = auth.currentUser();
const jwt = user.jwt();
jwt
  .then(response => debugPrint("This is a JWT token"))
  .catchError((error) {
    debugPrint("Error fetching JWT token");
    rethrow;
  });
```

Example response object:

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE1MjUyMTk4MTYsInN1YiI6ImE5NG.98YDkB6B9JbBlDlqqef2nme2tkAnsi30QVys9aevdCw debugger eval code:1:43
```

### Logout a user

This function removes the current session of the user and log out the user

`user.logout()`

Example usage:

```js
const user = auth.currentUser();
user
  .logout()
  .then(response => debugPrint("User logged out"))
  .catchError((error){
    debugPrint("Failed to logout user");
    rethrow;
  });
```

## See also

* [gotrue](https://github.com/netlify/gotrue)
* [gotrue-js](https://github.com/netlify/gotrue-js)
* [netlify-identity-widget](https://github.com/netlify/netlify-identity-widget/)
* [micro-api-client-library](https://github.com/netlify/micro-api-client-lib)
* [Netlify identity docs](https://www.netlify.com/docs/identity/)