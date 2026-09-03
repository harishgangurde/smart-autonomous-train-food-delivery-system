class Robot {
  final String robotId;
  final String? ipAddress;
  final String status; // ONLINE | OFFLINE
  final double? lastSeen;
  final String? currentCoach;
  final String? currentSeat;
  final String? currentOrderId;
  final String activity; // IDLE | MOVING | DELIVERING | RETURNING

  Robot({
    required this.robotId,
    this.ipAddress,
    this.status = 'OFFLINE',
    this.lastSeen,
    this.currentCoach,
    this.currentSeat,
    this.currentOrderId,
    this.activity = 'IDLE',
  });

  factory Robot.fromJson(Map<String, dynamic> json) => Robot(
        robotId: json['robotId'],
        ipAddress: json['ipAddress'],
        status: json['status'] ?? 'OFFLINE',
        lastSeen: (json['lastSeen'] as num?)?.toDouble(),
        currentCoach: json['currentCoach'],
        currentSeat: json['currentSeat'],
        currentOrderId: json['currentOrderId'],
        activity: json['activity'] ?? 'IDLE',
      );

  Robot copyWith({
    String? ipAddress,
    String? status,
    String? currentCoach,
    String? currentSeat,
    String? activity,
  }) =>
      Robot(
        robotId: robotId,
        ipAddress: ipAddress ?? this.ipAddress,
        status: status ?? this.status,
        lastSeen: lastSeen,
        currentCoach: currentCoach ?? this.currentCoach,
        currentSeat: currentSeat ?? this.currentSeat,
        currentOrderId: currentOrderId,
        activity: activity ?? this.activity,
      );
}
