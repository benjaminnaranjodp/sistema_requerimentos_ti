enum UserRole { user, it }

class User {
  final String id;
  final String username;
  final UserRole role;

  User({required this.id, required this.username, required this.role});
}
