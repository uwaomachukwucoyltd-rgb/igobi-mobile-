class IgobiUser {
  IgobiUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.roles,
    required this.mfaEnabled,
    required this.hasPassword,
    this.phone,
    this.avatarUrl,
    this.selectedReligiousOrgId,
  });

  factory IgobiUser.fromJson(Map<String, dynamic> json) => IgobiUser(
        id: json['id'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        roles: (json['roles'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(growable: false),
        mfaEnabled: (json['mfaEnabled'] as bool?) ?? false,
        hasPassword: (json['hasPassword'] as bool?) ?? true,
        selectedReligiousOrgId: json['selectedReligiousOrgId'] as String?,
      );

  final String id;
  final String email;
  final String? displayName;
  final String? phone;
  final String? avatarUrl;
  final List<String> roles;
  final bool mfaEnabled;
  /// False for accounts created via Google Sign-In with no local password
  /// set. UI uses this to hide the "change password" affordance.
  final bool hasPassword;
  /// The vendor-service religious org id this user has chosen. Null until
  /// the customer picks one — every transaction's 10% donation will then
  /// flow to this org.
  final String? selectedReligiousOrgId;
}

class AuthResult {
  AuthResult({required this.user, required this.accessToken});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return AuthResult(
      user: IgobiUser.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['accessToken'] as String,
    );
  }

  final IgobiUser user;
  final String accessToken;
}
