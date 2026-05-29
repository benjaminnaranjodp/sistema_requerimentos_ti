import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        .listen((snapshot) {
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
      _requests = snapshot.docs
          .map((doc) => Request.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
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
      _requests = snapshot.docs
          .map((doc) => Request.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  
  Future<void> addRequest(Request request) async {
    await _firestore.collection('requests').add(request.toMap());
  }

  
  Future<void> updateRequestStatus(String requestId, RequestStatus status, {String? comment, String? adminImageUrl}) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': status.name,
      'adminComment': comment,
      if (adminImageUrl != null) 'adminImageUrl': adminImageUrl,
    });
  }

  
  Future<String?> uploadImage(Uint8List bytes, String folder) async {
    try {
      final base64Image = base64Encode(bytes);

      
      const apiKey = '06222bfae6f4afef6856dff2e1183307';
      final url = Uri.parse('https://api.imgbb.com/1/upload');

      final response = await http.post(url, body: {
        'key': apiKey,
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['data']['url'];
      } else {
        debugPrint('Error from ImgBB: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading image to ImgBB: $e');
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
