import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.it;

  AuthProvider() {
    _auth.authStateChanges().listen((firebase.User? user) {
      if (user != null) {
        final userEmail = user.email ?? '';
        final fullDisplayName = user.displayName ?? '';
        final parts = fullDisplayName.split('|');
        
        final realName = parts.isNotEmpty && parts[0].isNotEmpty 
            ? parts[0] 
            : (userEmail.isNotEmpty ? userEmail.split('@').first : 'Usuario');
            
        final roleStr = parts.length > 1 ? parts[1] : 'docente';
        final assignedRole = (roleStr == 'ti') ? UserRole.it : UserRole.user;
        
        _currentUser = User(
          id: user.uid, 
          username: realName, 
          role: assignedRole
        );
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Correo o contraseña incorrectos';
      }
      return e.message;
    } catch (e) {
      return 'Ocurrió un error inesperado';
    }
  }

  Future<String?> register(String name, String email, String password, String role) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await credential.user?.updateDisplayName('$name|$role');
      
      await credential.user?.reload();
      final updatedUser = _auth.currentUser;
      if (updatedUser != null) {
        final assignedRole = (role == 'ti') ? UserRole.it : UserRole.user;
        _currentUser = User(
          id: updatedUser.uid,
          username: name,
          role: assignedRole
        );
        notifyListeners();
      }
      
      try {
        await credential.user?.sendEmailVerification();
      } catch (emailError) {
        // En caso de que Firebase falle silenciosamente al enviar el correo
        debugPrint('Error enviando correo de verificación: $emailError');
      }
      
      return null;
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        return 'La contraseña proporcionada es demasiado débil.';
      } else if (e.code == 'email-already-in-use') {
        return 'Ya existe una cuenta con ese correo electrónico.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final provider = firebase.GoogleAuthProvider();
        await _auth.signInWithPopup(provider);
        return null;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return 'Inicio de sesión cancelado';

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = firebase.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);
        return null;
      }
    } on firebase.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return 'Error al iniciar sesión con Google';
    }
  }
  
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on firebase.FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error al enviar recuperación de contraseña';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
