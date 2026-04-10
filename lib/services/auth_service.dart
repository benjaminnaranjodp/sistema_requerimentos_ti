class AuthService {
  Future<bool> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));

    return email == 'usuario@test.cl' && password == '123';
  }
}