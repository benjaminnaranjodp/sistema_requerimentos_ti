import 'package:flutter/material.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.it;

  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network request
    
    if (email == 'ti@test.cl' && password == '123') {
      _currentUser = User(id: '1', username: 'Departamento TI', role: UserRole.it);
      notifyListeners();
      return true;
    } else if (email == 'usuario@test.cl' && password == '123') {
      _currentUser = User(id: '2', username: 'Docente', role: UserRole.user);
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
