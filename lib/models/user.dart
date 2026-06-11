enum UserRole { user, it, admin }

class User {
  final String id;
  final String username;
  final String email;
  final UserRole role;
  final String? fcmToken;
  final bool isDarkMode;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.fcmToken,
    this.isDarkMode = false,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    UserRole? role,
    String? fcmToken,
    bool? isDarkMode,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toMap() {
    String roleStr;
    if (role == UserRole.it) {
      roleStr = 'ti';
    } else if (role == UserRole.admin) {
      roleStr = 'admin';
    } else {
      roleStr = 'docente';
    }

    return {
      'uid': id,
      'username': username,
      'email': email,
      'role': roleStr,
      if (fcmToken != null) 'fcmToken': fcmToken,
      'isDarkMode': isDarkMode,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    UserRole parseRole(String? role) {
      if (role == 'ti') return UserRole.it;
      if (role == 'admin') return UserRole.admin;
      return UserRole.user;
    }

    return User(
      id: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: parseRole(map['role']),
      fcmToken: map['fcmToken'],
      isDarkMode: map['isDarkMode'] ?? false,
    );
  }
}
