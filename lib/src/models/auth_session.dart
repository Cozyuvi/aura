import 'app_user.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.expiresIn,
    required this.rememberMe,
    required this.user,
  });

  final String token;
  final String expiresIn;
  final bool rememberMe;
  final AppUser user;

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'expiresIn': expiresIn,
      'rememberMe': rememberMe,
      'user': user.toJson(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: (json['token'] as String?)?.trim() ?? '',
      expiresIn: (json['expiresIn'] as String?)?.trim() ?? '',
      rememberMe: json['rememberMe'] == true,
      user: AppUser.fromJson((json['user'] as Map<String, dynamic>?) ?? <String, dynamic>{}),
    );
  }
}
