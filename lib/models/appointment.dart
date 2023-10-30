import '../models/typeEvent.dart';

class Appointment {
  final int id;
  final String schedule;
  final String description;
  final int repeatEach;
  final String createAt;
  final String updateAt;
  final Type appointmentType;

  Appointment(
     this.id,
     this.schedule,
     this.description,
     this.repeatEach,
     this.createAt,
     this.updateAt,
     this.appointmentType,
  );
}