enum RequestStatus { pending, accepted, rejected }

class Request {
  final String id;
  final String userId;
  final String moduleId;
  final DateTime date;
  final String time;
  final String type;
  final String description;
  RequestStatus status;
  String? adminComment;

  Request({
    required this.id,
    required this.userId,
    required this.moduleId,
    required this.date,
    required this.time,
    required this.type,
    required this.description,
    this.status = RequestStatus.pending,
    this.adminComment,
  });
}
