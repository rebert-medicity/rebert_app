import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main_app.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'models/users.dart';

void main() async {
  await _initHive();
  await initializeDateFormatting('ec', null);
  initializeDateFormatting().then((_) => runApp(MainApp()));
}

Future<void> _initHive() async{
  await Hive.initFlutter();
  await Hive.initFlutter();
  Hive.registerAdapter(UserAdapter());
}