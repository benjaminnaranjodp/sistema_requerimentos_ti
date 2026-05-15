import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.it;

  AuthProvider() {
    _auth.authStateChanges().listen((firebase.User? user) async {
      if (user != null) {
        await _loadUserFromFirestore(user.uid, user.email ?? '');
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  /// Loads user data from Firestore 'users' collection.
  /// If the document doesn't exist yet (e.g., Google sign-in first time), creates it.
  Future<void> _loadUserFromFirestore(String uid, String email) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = User.fromMap(doc.data()!);
      } else {
        // Fallback: create user doc from Auth profile (e.g., first Google login)
        final firebaseUser = _auth.currentUser;
        final displayName = firebaseUser?.displayName ?? email.split('@').first;
        
        // Parse legacy displayName format "name|role"
        final parts = displayName.split('|');
        final realName = parts.isNotEmpty && parts[0].isNotEmpty 
            ? parts[0] 
            : email.split('@').first;
        final roleStr = parts.length > 1 ? parts[1] : 'docente';
        final role = roleStr == 'ti' ? UserRole.it : UserRole.user;

        _currentUser = User(
          id: uid,
          username: realName,
          email: email,
          role: role,
        );
        await _firestore.collection('users').doc(uid).set(_currentUser!.toMap());
      }
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
      // Fallback if Firestore is unreachable
      _currentUser = User(
        id: uid,
        username: email.split('@').first,
        email: email,
        role: UserRole.user,
      );
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user != null && !user.emailVerified) {
        final creationTime = user.metadata.creationTime;
        if (creationTime != null && DateTime.now().difference(creationTime).inMinutes > 15) {
          await user.delete();
          await logout();
          return 'El tiempo para verificar la cuenta ha expirado (15 min). Por favor, regístrate de nuevo.';
        }
        await logout();
        return 'Por favor verifica tu correo electrónico antes de iniciar sesión. Tienes 15 minutos desde tu registro.';
      }

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
      
      await credential.user?.updateDisplayName(name);

      final assignedRole = (role == 'ti') ? UserRole.it : UserRole.user;
      final newUser = User(
        id: credential.user!.uid,
        username: name,
        email: email,
        role: assignedRole,
      );

      // Save user with role to Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());

      try {
        await credential.user?.sendEmailVerification();
      } catch (emailError) {
        // En caso de que Firebase falle silenciosamente al enviar el correo
        debugPrint('Error enviando correo de verificación: $emailError');
      }
      
      await _auth.signOut();
      _currentUser = null;
      notifyListeners();
      
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

  Future<String?> updateProfile(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        await _firestore.collection('users').doc(user.uid).update({'username': newName});
        
        if (_currentUser != null) {
          _currentUser = User(
            id: _currentUser!.id,
            username: newName,
            email: _currentUser!.email,
            role: _currentUser!.role,
          );
          notifyListeners();
        }
        return null;
      }
      return 'No hay usuario autenticado';
    } catch (e) {
      return 'Error al actualizar el perfil';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<String?> updateUsername(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        // Ensure user exists in firestore before update
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          await _firestore.collection('users').doc(user.uid).update({'username': newName});
        }
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(username: newName);
          notifyListeners();
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error updating username: $e');
      return 'Error al actualizar el nombre';
    }
  }
}
