import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestStatus { pending, accepted, rejected }

class Request {
  final String id;
  final String userId;
  final String userName;
  final String moduleId;
  final DateTime date;
  final String time;
  final String type;
  final String description;
  RequestStatus status;
  String? adminComment;
  final String? imageUrl;
  String? adminImageUrl;

  Request({
    required this.id,
    required this.userId,
    this.userName = '',
    required this.moduleId,
    required this.date,
    required this.time,
    required this.type,
    required this.description,
    this.status = RequestStatus.pending,
    this.adminComment,
    this.imageUrl,
    this.adminImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'moduleId': moduleId,
      'date': Timestamp.fromDate(date),
      'time': time,
      'type': type,
      'description': description,
      'status': status.name,
      'adminComment': adminComment,
      'imageUrl': imageUrl,
      'adminImageUrl': adminImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Request.fromMap(String id, Map<String, dynamic> map) {
    RequestStatus parseStatus(String? s) {
      switch (s) {
        case 'accepted':
          return RequestStatus.accepted;
        case 'rejected':
          return RequestStatus.rejected;
        default:
          return RequestStatus.pending;
      }
    }

    return Request(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      moduleId: map['moduleId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: map['time'] ?? '',
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      status: parseStatus(map['status']),
      adminComment: map['adminComment'],
      imageUrl: map['imageUrl'],
      adminImageUrl: map['adminImageUrl'],
    );
  }
}
