import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/database_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NetworkProvider extends ChangeNotifier {
  bool _isOffline = false;
  bool get isOffline => _isOffline;
  
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);

    _subscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    bool isCurrentlyOffline = results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none);
    
    // Si acaba de volver el internet (transición de offline a online)
    if (_isOffline && !isCurrentlyOffline) {
      _syncPendingData();
    }
    
    if (_isOffline != isCurrentlyOffline) {
      _isOffline = isCurrentlyOffline;
      notifyListeners();
    }
  }

  Future<void> _syncPendingData() async {
    debugPrint("🌐 Conexión restaurada: Sincronizando datos pendientes...");
    try {
      final pending = await DatabaseHelper().getPendingRequests();
      
      if (pending.isEmpty) {
        debugPrint("No hay datos pendientes para sincronizar.");
        return;
      }
      
      final firestore = FirebaseFirestore.instance;
      for (var record in pending) {
        final id = record['id'] as int;
        Map<String, dynamic> data = jsonDecode(record['data'] as String);
        
        if (data['date'] != null) {
          data['date'] = Timestamp.fromDate(DateTime.parse(data['date'] as String));
        }
        if (data['status'] == 'offlinePending') {
          data['status'] = 'pending';
        }
        data['createdAt'] = FieldValue.serverTimestamp();
        
        await firestore.collection('requests').add(data);
        await DatabaseHelper().removePendingRequest(id);
      }
      
      debugPrint("✅ Sincronización de ${pending.length} tickets completada con SQLite.");
    } catch (e) {
      debugPrint("Error al sincronizar datos offline: $e");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
