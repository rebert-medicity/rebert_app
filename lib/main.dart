import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main_app.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  await _initHive();
  initializeDateFormatting().then((_) => runApp(MainApp()));
}

Future<void> _initHive() async{
  await Hive.initFlutter();
  await Hive.openBox("login");
  await Hive.openBox("accounts");
}