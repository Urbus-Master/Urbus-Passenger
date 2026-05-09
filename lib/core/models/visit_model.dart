import 'package:intl/intl.dart';

class VisitModel {
  final int id;
  final DateTime arrivedAt;
  final String unitNumber;
  final int unitId;
  final bool wasOnTime;
  final int delayMinutes;
  final String checkpointName;
  final int checkpointId;

  const VisitModel({
    required this.id,
    required this.arrivedAt,
    required this.unitNumber,
    required this.unitId,
    required this.wasOnTime,
    required this.delayMinutes,
    required this.checkpointName,
    required this.checkpointId,
  });

  // Getters requeridos por VisitCard
  String get date => DateFormat('dd/MM/yyyy').format(arrivedAt);
  String get time => DateFormat('HH:mm').format(arrivedAt);

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'],
      arrivedAt: DateTime.parse(json['arrivedAt']),
      unitNumber: json['unitNumber'],
      unitId: json['unitId'],
      wasOnTime: json['wasOnTime'],
      delayMinutes: json['delayMinutes'],
      checkpointName: json['checkpointName'],
      checkpointId: json['checkpointId'],
    );
  }
}
