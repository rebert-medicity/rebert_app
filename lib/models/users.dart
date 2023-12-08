import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class User {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String? username;

  @HiveField(2)
  final String? password;

  @HiveField(3)
  final String? firstName;

  @HiveField(4)
  final String? lastName;

  @HiveField(5)
  final String? email;

  @HiveField(6)
  final String? role;

  @HiveField(7)
  final String? token;

  User(this.id, this.username, this.password, this.firstName, this.lastName,
      this.email, this.role, this.token);

  Map toJson() => {
        'id': id,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'token': token,
      };
}

class UserAdapter extends TypeAdapter<User> {
  @override
  final typeId = 0; // Identificador único para el tipo de objeto

  @override
  User read(BinaryReader reader) {
    // Lee los campos de User desde la caja binaria
    final id = reader.read(0); // Índice 0 para el campo 'id'
    final username = reader.read(1); // Índice 1 para el campo 'username'
    final password = reader.read(2); // Índice 2 para el campo 'password'
    final firstName = reader.read(3); // Índice 3 para el campo 'firstName'
    final lastName = reader.read(4); // Índice 4 para el campo 'lastName'
    final email = reader.read(5); // Índice 5 para el campo 'email'
    final role = reader.read(6); // Índice 6 para el campo 'role'
    final token = reader.read(7); // Índice 7 para el campo 'token'

    return User(
        id, username, password, firstName, lastName, email, role, token);
  }

  @override
  void write(BinaryWriter writer, User obj) {
    // Escribe los campos de User en la caja binaria, utilizando valores predeterminados si son nulos
    writer.write(obj.id ?? 0); // Valor predeterminado 0 para id si es nulo
    writer.write(
        obj.username ?? ''); // Valor predeterminado cadena vacía si es nulo
    writer.write(
        obj.password ?? ''); // Valor predeterminado cadena vacía si es nulo
    writer.write(
        obj.firstName ?? ''); // Valor predeterminado cadena vacía si es nulo
    writer.write(
        obj.lastName ?? ''); // Valor predeterminado cadena vacía si es nulo
    writer
        .write(obj.email ?? ''); // Valor predeterminado cadena vacía si es nulo
    writer
        .write(obj.role ?? ''); // Valor predeterminado cadena vacía si es nulo
    writer
        .write(obj.token ?? ''); // Valor predeterminado cadena vacía si es nulo
  }
}
