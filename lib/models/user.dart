enum UserRole { user, it }

class User {
  final String id;
  final String username;
  final String email;
  final UserRole role;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'username': username,
      'email': email,
      'role': role == UserRole.it ? 'ti' : 'docente',
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] == 'ti' ? UserRole.it : UserRole.user,
    );
  }
}
