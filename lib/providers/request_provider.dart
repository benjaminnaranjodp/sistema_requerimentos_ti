import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request.dart';

class RequestProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Request> _requests = [];
  StreamSubscription? _subscription;

  List<Request> get requests => _requests;

  /// Listen to all requests in real-time (for TI admin view)
  void listenAllRequests() {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _requests = snapshot.docs
          .map((doc) => Request.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  /// Listen to requests for a specific user (docente view)
  void listenUserRequests(String userId) {
    _subscription?.cancel();
    _subscription = _firestore
        .collection('requests')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      _requests = snapshot.docs
          .map((doc) => Request.fromMap(doc.id, doc.data()))
          .toList();
      notifyListeners();
    });
  }

  /// Create a new request in Firestore
  Future<void> addRequest(Request request) async {
    await _firestore.collection('requests').add(request.toMap());
  }

  /// Update request status (accept/reject by TI)
  Future<void> updateRequestStatus(String requestId, RequestStatus status, {String? comment}) async {
    await _firestore.collection('requests').doc(requestId).update({
      'status': status.name,
      'adminComment': comment,
    });
  }

  /// Delete a request from Firestore
  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection('requests').doc(requestId).delete();
  }

  /// Update an existing request in Firestore
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
