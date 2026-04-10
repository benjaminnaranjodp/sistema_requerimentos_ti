import 'package:flutter/material.dart';
import '../models/request.dart';

class RequestProvider with ChangeNotifier {
  final List<Request> _requests = [];

  List<Request> get requests => _requests;

  void addRequest(Request request) {
    _requests.add(request);
    notifyListeners();
  }

  void updateRequestStatus(String requestId, RequestStatus status, {String? comment}) {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index].status = status;
      _requests[index].adminComment = comment;
      notifyListeners();
    }
  }

  List<Request> getRequestsForUser(String userId) {
    return _requests.where((r) => r.userId == userId).toList();
  }
}
