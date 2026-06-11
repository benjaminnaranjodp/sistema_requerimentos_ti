import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  StreamSubscription? _userSub;

  ThemeProvider() {
    _loadTheme();
    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _userSub?.cancel();
        _userSub = FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().listen((doc) {
          if (doc.exists && doc.data() != null && doc.data()!.containsKey('isDarkMode')) {
            bool dbDark = doc.data()!['isDarkMode'] ?? false;
            if ((_themeMode == ThemeMode.dark) != dbDark) {
              _themeMode = dbDark ? ThemeMode.dark : ThemeMode.light;
              notifyListeners();
              SharedPreferences.getInstance().then((prefs) => prefs.setBool('isDarkMode', dbDark));
            }
          }
        });
      } else {
        _userSub?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  void toggleTheme(bool isOn) async {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isOn);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'isDarkMode': isOn,
        });
      } catch (e) {
        debugPrint('Error saving theme to Firestore: $e');
      }
    }
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isDarkMode = prefs.getBool('isDarkMode');
    if (isDarkMode != null) {
      _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
      notifyListeners();
    }
  }
}
