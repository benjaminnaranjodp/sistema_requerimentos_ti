import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  UserRole? _simulatedRole;

  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _currentUser;
  UserRole get currentRole => _simulatedRole ?? _currentUser?.role ?? UserRole.user;
  UserRole? get simulatedRole => _simulatedRole;

  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => currentRole == UserRole.it;
  bool get isRealAdmin => _currentUser?.role == UserRole.admin;

  void simulateRole(UserRole? role) {
    _simulatedRole = role;
    notifyListeners();
  }

  AuthProvider() {
    _auth.authStateChanges().listen((firebase.User? user) async {
      if (user != null) {
        await _loadUserFromFirestore(user.uid, user.email ?? '');
      } else {
        _currentUser = null;
        _simulatedRole = null;
      }
      notifyListeners();
    });
  }

  
  
  Future<void> _loadUserFromFirestore(String uid, String email) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = User.fromMap(doc.data()!);
      } else {
        
        final firebaseUser = _auth.currentUser;
        final displayName = firebaseUser?.displayName ?? email.split('@').first;
        
        
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
      
      
      await _updateFcmToken(uid);
      
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
      
      _currentUser = User(
        id: uid,
        username: email.split('@').first,
        email: email,
        role: UserRole.user,
      );
    }
  }

  Future<void> _updateFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(uid).update({'fcmToken': token});
        if (_currentUser != null) {
          _currentUser = _currentUser!.copyWith(fcmToken: token);
          notifyListeners();
        }
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        await _firestore.collection('users').doc(uid).update({'fcmToken': newToken});
      });
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
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

      
      await _firestore.collection('users').doc(credential.user!.uid).set(newUser.toMap());

      try {
        await credential.user?.sendEmailVerification();
      } catch (emailError) {
        
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
    _simulatedRole = null;
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<String?> updateUsername(String newName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        
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

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        
        firebase.AuthCredential credential = firebase.EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(newPassword);
        return null;
      }
      return 'No hay usuario autenticado';
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'La contraseña actual es incorrecta';
      }
      return e.message;
    } catch (e) {
      return 'Error al cambiar la contraseña';
    }
  }
}
