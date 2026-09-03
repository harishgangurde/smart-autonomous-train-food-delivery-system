class SecurityAlert {
  final String alertId;
  final String robotId;
  final String coachNo;
  final String alertType;
  final double timestamp;
  final String status; // ACTIVE | ACKNOWLEDGED
  final String? acknowledgedBy;

  SecurityAlert({
    required this.alertId,
    required this.robotId,
    required this.coachNo,
    required this.alertType,
    required this.timestamp,
    this.status = 'ACTIVE',
    this.acknowledgedBy,
  });

  factory SecurityAlert.fromJson(Map<String, dynamic> json) => SecurityAlert(
        alertId: json['alertId'],
        robotId: json['robotId'],
        coachNo: json['coachNo'],
        alertType: json['alertType'],
        timestamp: (json['timestamp'] as num).toDouble(),
        status: json['status'] ?? 'ACTIVE',
        acknowledgedBy: json['acknowledgedBy'],
      );
}
