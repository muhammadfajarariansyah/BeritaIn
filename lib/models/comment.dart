class Comment {
  final String id;
  final String reportId;
  final String userName;
  final String message;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.reportId,
    required this.userName,
    required this.message,
    required this.createdAt,
  });

  // Convert Comment object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'userName': userName,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create Comment object from JSON
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? '',
      reportId: json['reportId'] ?? '',
      userName: json['userName'] ?? '',
      message: json['message'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] ?? 0),
    );
  }

  // Create a copy of Comment with modified fields
  Comment copyWith({
    String? id,
    String? reportId,
    String? userName,
    String? message,
    DateTime? createdAt,
  }) {
    return Comment(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Comment{id: $id, reportId: $reportId, userName: $userName, message: $message, createdAt: $createdAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Comment &&
        other.id == id &&
        other.reportId == reportId &&
        other.userName == userName &&
        other.message == message &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        reportId.hashCode ^
        userName.hashCode ^
        message.hashCode ^
        createdAt.hashCode;
  }
}