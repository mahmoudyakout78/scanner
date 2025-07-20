class SelectionModel {
  final String id;
  final int timestamp;
  final String userId;

  SelectionModel({
    required this.id,
    required this.timestamp,
    required this.userId,
  });

  factory SelectionModel.fromMap(Map<dynamic, dynamic> map) {
    return SelectionModel(
      id: map['id'],
      timestamp: map['timestamp'],
      userId: map['userId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp,
      'userId': userId,
    };
  }
}
