import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rebert_app/models/users.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/appointment.dart';
import 'package:http/http.dart' as http;
import '../models/events.dart';
import '../models/typeEvent.dart';
import 'login.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late String _categorySelected;
  late String _medicitySelected;
  late String _userSelected;

  List<String> categorys = [];
  List<String> medicities = [];
  List<String> users = [];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Event>> events = {};
  TextEditingController _eventController = TextEditingController();
  late final ValueNotifier<List<Event>> _selectedEvents;

  late final String username;
  late final String token;
  late final int userid;
  late final String fullname;
  late final String role;

  late List<Type> categoryList;
  late List<Medicity> medicityList;
  late List<User> userList;

  _HomeState() {
    _categorySelected = '';
    _medicitySelected = '';
    _userSelected = '';
    _selectedEvents = ValueNotifier([]);
  }

  Future<void> _startAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //Guardar en la memoria cache
    userid = prefs.getInt('id') ?? 0;
    username = prefs.getString('username') ?? '';
    fullname = prefs.getString('fullname') ?? '';
    token = prefs.getString('token') ?? '';
    role = prefs.getString('role') ?? '';
  }

  @override
  void initState() {
    super.initState();
    _startAuth().then((value) {
      setState(() {
        _updateCategories();
        _updateMedicity();
        _updateUsers();
        _fetchAppointments().then((appointments) {
          setState(() {
            events = generateEvents(appointments);
          });
        });
      });
    });

    _selectedDay = _focusedDay;
  }

  Future<void> _updateCategories() async {
    categoryList = await _fetchData();
    final categoryNames = categoryList
        .where((category) => category.name != null)
        .map((category) => category.name!)
        .toList();

    setState(() {
      categorys = categoryNames;
    });
  }

  Future<void> _updateMedicity() async {
    medicityList = await _fetchMedicity();
    final names = medicityList
        .where((item) => item.name != null)
        .map((item) => item.name!)
        .toList();

    setState(() {
      medicities = names;
    });
  }

  Future<void> _updateUsers() async {
    userList = await _fetchUsers();
    final names = userList
        .where((item) => item.firstName != null)
        .map((item) => item.firstName! + " " + item.lastName!)
        .toList();

    setState(() {
      users = names;
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(fullname + ' (' + role + ')'),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.exit_to_app),
          onPressed: () {
            _logout();
          },
        ),
      ],
    );
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Login();
        },
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          onPressed: _addSeizer,
          child: Icon(Icons.person),
        ),
        SizedBox(width: 16),
        FloatingActionButton(
          onPressed: _addEvent,
          child: Icon(Icons.add),
        ),
        SizedBox(width: 16),
        FloatingActionButton(
          onPressed: _showDayEvents,
          child: Icon(Icons.search),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        TableCalendar(
          locale: 'es_EC',
          headerStyle:
              HeaderStyle(titleCentered: true, formatButtonVisible: false),
          firstDay: kFirstDay,
          lastDay: kLastDay,
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          rangeSelectionMode: _rangeSelectionMode,
          eventLoader: _getEventsForDay,
          onDaySelected: _onDaySelected,
          onFormatChanged: _onFormatChanged,
          onPageChanged: _onPageChanged,
        ),
      ],
    );
  }

  void _addEvent() {
    _eventController.clear();
    TimeOfDay? selectedTime;
    String? categorySelected =
        categorys.first; // Establece un valor predeterminado para la categoría
    String? medicitySelected = medicities.first;
    String? userSelected = users.first;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: Text("Añadir un evento"),
              content: Column(
                children: [
                  DropdownButton<String>(
                    value: medicitySelected,
                    onChanged: (String? newValue) {
                      setState(() {
                        medicitySelected = newValue;
                      });
                    },
                    items: medicities.map((String name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                  ),
                  DropdownButton<String>(
                    value: categorySelected,
                    onChanged: (String? newValue) {
                      setState(() {
                        categorySelected = newValue;
                      });
                    },
                    items: categorys.map((String categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                  ),
                  DropdownButton<String>(
                    value: userSelected,
                    onChanged: (String? newValue) {
                      setState(() {
                        userSelected = newValue;
                      });
                    },
                    items: users.map((String name) {
                      return DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                  ),
                  TextField(
                    controller: _eventController,
                    decoration: InputDecoration(labelText: 'Evento'),
                  ),
                  Row(
                    children: [
                      Text('Hora: ${selectedTime?.format(context) ?? ''}'),
                      IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () async {
                          selectedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    DateTime? day = _selectedDay;
                    Duration timeOfDayDuration = Duration(
                      hours: selectedTime!.hour + 5,
                      minutes: selectedTime!.minute,
                    );

                    DateTime newDateTime = day!.add(timeOfDayDuration);

                    int millisecondsSinceEpoch =
                        newDateTime.millisecondsSinceEpoch;

                    createAppointment(
                      id: 0,
                      schedule: millisecondsSinceEpoch.toString(),
                      description: _eventController.text,
                      repeatEvery: 0,
                      appointmentType:
                          categoryList[categorys.indexOf(categorySelected!)]
                              .id!,
                      medicity:
                          medicityList[medicities.indexOf(medicitySelected!)]
                              .id!,
                      withuser:
                          userList[users.indexOf(userSelected!)]
                              .id!,
                    );
                    if (_selectedDay != null) {
                      List<Event> listaAux = _getEventsForDay(_selectedDay!);
                      listaAux.add(Event(categorySelected!,
                          _eventController.text, selectedTime!, 0));
                      events[_selectedDay!] = listaAux;
                      _selectedEvents.value = listaAux;
                    } else {
                      events.addAll({
                        _selectedDay!: [
                          Event(categorySelected!, _eventController.text,
                              selectedTime!, 0)
                        ]
                      });
                      _selectedEvents.value = _getEventsForDay(_selectedDay!);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text("Agregar"),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _addSeizer() {
    _eventController.clear();
    TimeOfDay? selectedTime;
    String? medicitySelected = medicities.first;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: Text("Convulsiones"),
              content: Column(
                children: [
                  TextField(
                    controller: _eventController,
                    decoration: InputDecoration(labelText: 'Descripcion'),
                  ),
                  Row(
                    children: [
                      Text('Hora: ${selectedTime?.format(context) ?? ''}'),
                      IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () async {
                          selectedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    DateTime? day = _selectedDay;
                    Duration timeOfDayDuration = Duration(
                      hours: selectedTime!.hour + 5,
                      minutes: selectedTime!.minute,
                    );
                    DateTime newDateTime = day!.add(timeOfDayDuration);

                    int millisecondsSinceEpoch =
                        newDateTime.millisecondsSinceEpoch;

                    createAppointment(
                      id: 0,
                      schedule: millisecondsSinceEpoch.toString(),
                      description: _eventController.text,
                      repeatEvery: 0,
                      appointmentType: 7,
                    );
                    if (_selectedDay != null) {
                      List<Event> listaAux = _getEventsForDay(_selectedDay!);
                      listaAux.add(Event(medicitySelected!,
                          _eventController.text, selectedTime!, 0));
                      events[_selectedDay!] = listaAux;
                      _selectedEvents.value = listaAux;
                    } else {
                      events.addAll({
                        _selectedDay!: [
                          Event(medicitySelected!, _eventController.text,
                              selectedTime!, 0)
                        ]
                      });
                      _selectedEvents.value = _getEventsForDay(_selectedDay!);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text("Agregar"),
                )
              ],
            );
          },
        );
      },
    );
  }

  List<BuildContext> _openDialogs = [];
  Future<void> _showDayEvents() async {
    _fetchAppointments().then((appointments) {
      setState(() {
        events = generateEvents(appointments);
      });
    });
    _eventController.clear();

    for (BuildContext dialogContext in _openDialogs) {
      Navigator.of(dialogContext).pop();
    }

    _openDialogs.clear();

    bool? edited = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          scrollable: true,
          title: Text("Eventos del día"),
          content: Container(
            width: 300,
            height: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ValueListenableBuilder<List<Event>>(
                    valueListenable: _selectedEvents,
                    builder: (context, value, _) {
                      final eventsForDay =
                          _getEventsForDay(_selectedDay ?? DateTime.now());
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: eventsForDay.length,
                        itemBuilder: (context, index) {
                          final event = value[index];
                          final eventIndex = index + 1;
                          final startTime = event.time;
                          final description = event.description;
                          return Container(
                            margin: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () {
                                print(
                                    "Tapped item $eventIndex: ${event.title}");
                              },
                              title: Text(
                                  '${startTime.hour}:${startTime.minute}    ${event.title}'),
                              subtitle: Text(description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      _editEvent(event, index);
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () {
                                      _deleteEvent(event);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (edited!) {
      setState(() {
        _selectedEvents.value =
            _getEventsForDay(_selectedDay ?? DateTime.now());
      });
    }

    _openDialogs.add(context);
  }

  void _editEvent(Event event, int index) {
    String eventTitle = event.title;
    String eventDescription = event.description;
    TimeOfDay selectedTime = event.time;
    int idAppointment = event.idAppointment;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: Text("Editar Evento"),
              content: Column(
                children: [
                  DropdownButton<String>(
                    value: eventTitle,
                    onChanged: (String? newValue) {
                      setState(() {
                        eventTitle = newValue!;
                      });
                    },
                    items: categorys.map((String categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                  ),
                  TextField(
                    controller: _eventController..text = eventDescription,
                    decoration: InputDecoration(labelText: 'Evento'),
                  ),
                  Row(
                    children: [
                      Text('Hora: ${selectedTime.format(context)}'),
                      IconButton(
                        icon: Icon(Icons.access_time),
                        onPressed: () async {
                          final newTime = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (newTime != null) {
                            setState(() {
                              selectedTime = newTime;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    DateTime? day = _selectedDay;
                    Duration timeOfDayDuration = Duration(
                      hours: selectedTime!.hour,
                      minutes: selectedTime!.minute,
                    );
                    DateTime newDateTime = day!.add(timeOfDayDuration);

                    newDateTime = newDateTime.toUtc();

                    int millisecondsSinceEpoch =
                        newDateTime.millisecondsSinceEpoch;

                    await updateAppointment(
                        id: idAppointment,
                        schedule: millisecondsSinceEpoch.toString(),
                        description: _eventController.text,
                        repeatEvery: 0,
                        appointmentType:
                            categoryList[categorys.indexOf(eventTitle!)].id!);

                    final editedEvent = Event(eventTitle, _eventController.text,
                        selectedTime, idAppointment);
                    final selectedDay = _selectedDay ?? DateTime.now();
                    final eventsForDay = _getEventsForDay(selectedDay);
                    if (index != -1) {
                      eventsForDay[index] = editedEvent;
                      events[selectedDay] = eventsForDay;
                      _selectedEvents.value = eventsForDay;
                      Navigator.pop(context, true);
                      Navigator.of(context).pop();
                      _showDayEvents();
                    }
                  },
                  child: Text("Guardar Cambios"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteEvent(Event event) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirmar eliminación"),
          content: Text("¿Seguro que quieres eliminar este evento?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                await deleteAppointment(id: event.idAppointment);
                await _fetchAppointments().then((appointments) {
                  setState(() {
                    events = generateEvents(appointments);
                  });
                });
                Navigator.pop(context, true);
                Navigator.of(context).pop();
                _showDayEvents();
              },
              child: Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  void _performEventDeletion(Event event) {
    final selectedDay = _selectedDay ?? DateTime.now();
    final eventsForDay = _getEventsForDay(selectedDay);
    eventsForDay.remove(event);
    events[selectedDay] = eventsForDay;
    _selectedEvents.value = eventsForDay;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  List<Event> _getEventsForDay(DateTime day) {
    return events[day] ?? [];
  }

  Future<List<Type>> _fetchData() async {
    final apiUrl =
        'https://medicity.edarkea.com/api/app-type/find-by-role/' + role;

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'auth-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      List<Type> types = responseData.map((typeData) {
        return Type(
          typeData['id'],
          typeData['name'],
          typeData['role'],
          typeData['createAt'],
          typeData['updateAt'],
        );
      }).toList();

      return types;
    } else {
      print('Error en la solicitud: ${response.statusCode}');
    }

    return [];
  }

  Future<List<User>> _fetchUsers() async {
    final apiUrl = 'https://medicity.edarkea.com/api/appointment/user/' + role;

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'auth-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      List<User> types = responseData.map((typeData) {
        return User(
            typeData['id'],
            typeData['username'],
            null,
            typeData['firstName'],
            typeData['lastName'],
            typeData['email'],
            typeData['role'],
            null);
      }).toList();

      return types;
    } else {
      print('Error en la solicitud: ${response.statusCode}');
    }

    return [];
  }

  Future<List<Medicity>> _fetchMedicity() async {
    final apiUrl = 'https://medicity.edarkea.com/api/medicity/all';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'auth-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      List<Medicity> types = responseData.map((typeData) {
        return Medicity(
          typeData['id'],
          typeData['name'],
        );
      }).toList();

      return types;
    } else {
      print('Error en la solicitud: ${response.statusCode}');
    }

    return [];
  }

  Future<List<Appointment>> _fetchAppointments() async {
    final apiUrl = 'https://medicity.edarkea.com/api/appointment';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: <String, String>{
        'auth-token': token,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      List<Appointment> appointments = responseData.map((appointmentData) {
        return Appointment(
          appointmentData['id'],
          appointmentData['schedule'],
          appointmentData['description'],
          appointmentData['repetatEach'],
          appointmentData['createAt'],
          appointmentData['updateAt'],
          Type(
            appointmentData['appointmentType']['id'],
            appointmentData['appointmentType']['name'],
            appointmentData['appointmentType']['role'],
            appointmentData['appointmentType']['createAt'],
            appointmentData['appointmentType']['updateAt'],
          )
        );
      }).toList();

      return appointments;
    } else {
      print('Error en la solicitud: ${response.statusCode}');
    }
    return [];
  }

  Map<DateTime, List<Event>> generateEvents(List<Appointment> appointments) {
    Map<DateTime, List<Event>> eventsMap = {};

    for (Appointment appointment in appointments) {
      String schedule = appointment.schedule;

      if (schedule != null && schedule != "NaN" && schedule.isNotEmpty) {
        int timestamp = int.parse(schedule);
        DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        dateTime = dateTime.toUtc();
        DateTime dateTimeAtMidnight =
            DateTime.utc(dateTime.year, dateTime.month, dateTime.day);
        if (!eventsMap.containsKey(dateTimeAtMidnight)) {
          eventsMap[dateTimeAtMidnight] = [];
        }

        String category = appointment.appointmentType.name ?? '';
        Event event = Event(
            category,
            appointment.description,
            TimeOfDay(hour: dateTime.hour - 5, minute: dateTime.minute),
            appointment.id);

        eventsMap[dateTimeAtMidnight]!.add(event);
      }
    }

    return eventsMap;
  }

  Future<void> createAppointment(
      {required int id,
      required String schedule,
      required String description,
      required int repeatEvery,
      required int appointmentType,req,
      int? medicity,
      int? withuser}) async {
    final apiUrl = 'https://medicity.edarkea.com/api/appointment';

    final appointmentData = {
      "id": id,
      "schedule": schedule,
      "description": description,
      "repetatEach": repeatEvery,
      "appointmentType": appointmentType,
      "medicity": medicity,
      "withuser": withuser,
    };

    final headers = {
      'auth-token': token,
      'Content-Type': 'application/json',
    };
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: headers,
      body: json.encode(appointmentData),
    );
  }

  Future<void> updateAppointment(
      {required int id,
      required String schedule,
      required String description,
      required int repeatEvery,
      required int appointmentType}) async {
    final apiUrl =
        'https://medicity.edarkea.com/api/appointment/update/' + id.toString();
    final appointmentData = {
      "id": id,
      "schedule": schedule,
      "description": description,
      "repetatEach": repeatEvery,
      "appointmentType": appointmentType,
    };

    final headers = {
      'auth-token': token,
      'Content-Type': 'application/json',
    };

    final response = await http.put(
      Uri.parse(apiUrl),
      headers: headers,
      body: json.encode(appointmentData),
    );
  }

  Future<void> deleteAppointment({required int id}) async {
    final apiUrl =
        'https://medicity.edarkea.com/api/appointment/delete/' + id.toString();
    final headers = {
      'auth-token': token,
      'Content-Type': 'application/json',
    };

    final response = await http.delete(Uri.parse(apiUrl), headers: headers);
  }
}
