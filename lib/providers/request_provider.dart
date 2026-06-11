import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/database_helper.dart';
import '../models/request.dart';
import '../services/notification_service.dart';

class RequestProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Request> _requests = [];
  StreamSubscription? _subscription;

  List<Request> get requests => _requests;

  
  void listenAllRequests() {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final req = Request.fromMap(change.doc.id, change.doc.data()!);
          NotificationService().showNotification(
            id: req.id.hashCode,
            title: 'Nueva Solicitud',
            body: 'El docente ${req.userName} ha enviado una solicitud.',
          );
        }
      }
      
      final dataList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      DatabaseHelper().saveRequestsCache(dataList, 'all');
      
      _requests = snapshot.docs
          .map((doc) => Request.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    }, onError: (error) async {
      final cached = await DatabaseHelper().getRequestsCache();
      if (cached.isNotEmpty) {
        final list = cached.map((e) => jsonDecode(e['data'] as String) as Map<String, dynamic>).toList();
        _requests = list.map((data) => Request.fromMap(data['id'], data)).toList();
        notifyListeners();
      }
    });
  }

  
  void listenUserRequests(String userId) {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final req = Request.fromMap(change.doc.id, change.doc.data()!);
          if (req.status != RequestStatus.pending) {
            String statusStr = req.status == RequestStatus.accepted ? 'Aceptada' : 'Rechazada';
            NotificationService().showNotification(
              id: req.id.hashCode,
              title: 'Solicitud $statusStr',
              body: 'Tu solicitud ha sido $statusStr por el departamento TI.',
            );
          }
        }
      }
      final dataList = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      DatabaseHelper().saveRequestsCache(dataList, 'user_$userId');

      _requests = snapshot.docs
          .map((doc) => Request.fromMap(doc.id, doc.data()))
          .toList();
      _mergeOfflineRequests();
    }, onError: (error) async {
      final cached = await DatabaseHelper().getRequestsCache();
      if (cached.isNotEmpty) {
        final list = cached.map((e) => jsonDecode(e['data'] as String) as Map<String, dynamic>).toList();
        _requests = list.map((data) => Request.fromMap(data['id'], data)).toList();
        notifyListeners();
      }
    });
  }

  
  Future<void> _mergeOfflineRequests() async {
    try {
      final pending = await DatabaseHelper().getPendingRequests();
      if (pending.isEmpty) {
        notifyListeners();
        return;
      }
      
      final offlineList = pending.map((record) {
        Map<String, dynamic> data = jsonDecode(record['data'] as String);
        return Request.fromMap(data['id'] ?? record['id'].toString(), data);
      }).toList();
      
      _requests = [...offlineList, ..._requests];
      notifyListeners();
    } catch (e) {
      debugPrint("Error merging offline requests: $e");
      notifyListeners();
    }
  }

  Future<void> addRequest(Request request) async {
    final results = await Connectivity().checkConnectivity();
    bool isOffline = results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none);
    
    if (isOffline) {
      request.status = RequestStatus.offlinePending;
      Map<String, dynamic> pendingData = {
        'id': request.id,
        'userId': request.userId,
        'userName': request.userName,
        'moduleId': request.moduleId,
        'date': request.date.toIso8601String(),
        'time': request.time,
        'type': request.type,
        'description': request.description,
        'status': request.status.name,
        'imageUrl': request.imageUrl,
      };
      await DatabaseHelper().addPendingRequest(jsonEncode(pendingData));
      debugPrint("Offline: Request saved to SQLite");
      
      // Añadir localmente para que se vea reflejado al instante
      _requests.insert(0, request);
      notifyListeners();
    } else {
      await _firestore.collection('requests').add(request.toMap());
    }
  }

  
  Future<void> updateRequestStatus(String requestId, RequestStatus status, {String? comment, String? adminImageUrl}) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': status.name,
      'adminComment': comment,
      if (adminImageUrl != null) 'adminImageUrl': adminImageUrl,
    });
  }

  
  /// Upload an image to Firebase Storage
  Future<String?> uploadImage(Uint8List bytes, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('$folder/$fileName');
      
      final uploadTask = ref.putData(
        bytes, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image to Firebase Storage: $e');
      return null;
    }
  }

  
  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).delete();
  }

  
  Future<void> updateRequest(Request request) async {
    await _firestore.collection('requests').doc(request.id).update({
      'moduleId': request.moduleId,
      'date': Timestamp.fromDate(request.date),
      'time': request.time,
      'type': request.type,
      'description': request.description,
    });
  }

  List<Request> getRequestsForUser(String userId) {
    return _requests.where((r) => r.userId == userId).toList();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
