import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:rebert_app/models/users.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';
import 'signup.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey();

  final FocusNode _focusNodePassword = FocusNode();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();

  bool _obscurePassword = true;
  String _errorText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              children: [
                const SizedBox(height: 150),
                Text(
                  "Rebert Medicity",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  "Inicia sesión con tu cuenta",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 60),
                TextFormField(
                  controller: _controllerUsername,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    labelText: "Usuario",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onEditingComplete: () => _focusNodePassword.requestFocus(),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor, ingrese su usuario.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _controllerPassword,
                  focusNode: _focusNodePassword,
                  obscureText: _obscurePassword,
                  keyboardType: TextInputType.visiblePassword,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: const Icon(Icons.password_outlined),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: _obscurePassword
                            ? const Icon(Icons.visibility_outlined)
                            : const Icon(Icons.visibility_off_outlined)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return "Por favor, ingrese su contraseña";
                    }
                    return null;
                  },
                ),
                // Mostrar el mensaje de error si existe
                if (_errorText.isNotEmpty)
                  Text(
                    _errorText,
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                const SizedBox(height: 60),
                Column(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          User? userLogin = await loginUser(
                              _controllerUsername.text,
                              _controllerPassword.text);
                          // Guarda el usuario en la caja
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          if (userLogin != null) {
                            //Guardar en la memoria cache
                            await prefs.setInt('id', userLogin.id ?? -1);
                            await prefs.setString('username', userLogin.username ?? '');
                            await prefs.setString('fullname', (userLogin.firstName ?? '') + " " + (userLogin.lastName ?? ''));
                            await prefs.setString('token', userLogin.token ?? '');
                            await prefs.setString('role', userLogin.role ?? '');
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return Home();
                                },
                              ),
                            );
                          } else {
                            // Actualizar el mensaje de error
                            setState(() {
                              _errorText = 'Credenciales incorrectas';
                            });
                          }
                        }
                      },
                      child: const Text("Iniciar Sesión"),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("¿No tienes una cuenta?"),
                        TextButton(
                          onPressed: () {
                            _formKey.currentState?.reset();
                            setState(() {
                              _errorText = '';
                            });
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) {
                                  return const Signup();
                                },
                              ),
                            );
                          },
                          child: const Text("Regístrate"),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _focusNodePassword.dispose();
    _controllerUsername.dispose();
    _controllerPassword.dispose();
    super.dispose();
  }
}

Future<User?> loginUser(String username, String password) async {
  const apiUrl = 'https://medicity.edarkea.com/api/v1.0/auth';

  final response = await http.post(
    Uri.parse(apiUrl),
    headers: <String, String>{
      'Content-Type': 'application/json',
    },
    body: jsonEncode(<String, String>{
      'email': username,
      'username': username,
      'password': password,
    }),
  );
  if (response.statusCode == 200) {
    final userJsonBody = json.decode(response.body);
    final userToken = response.headers['auth-token'];
    final user = User(
      userJsonBody['id'], // id
      userJsonBody['username'], // username
      userJsonBody['password'], // password
      userJsonBody['firstName'], // firstName
      userJsonBody['lastName'], // lastName
      userJsonBody['email'], // email
      userJsonBody['role'], // role
      userToken, // token
    );
    return user;
  } else {
    return null;
  }
}
