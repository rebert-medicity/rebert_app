import 'package:flutter/material.dart';
import 'package:rebert_app/ui/home.dart';
import 'ui/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 44, 141, 126),
        ),
      ),
      home: const Login(),
    );
  }

  Future<StatefulWidget> _startAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Guardar en la memoria cache
    var userid = prefs.getInt('id') ?? 0;
    if (userid == 0) {
      return const Login();
    }
    return const Home();
  }
}
