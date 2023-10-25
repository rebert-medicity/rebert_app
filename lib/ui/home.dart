import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'login.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils.dart';


class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? _categorySelected;
  List<String> categorys = ["Cita", "Medicina", "Otros"];
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOn;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<Event>> events = {};
  TextEditingController _eventController = TextEditingController();
  late final ValueNotifier<List<Event>> _selectedEvents;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier<List<Event>>(_getEventsForDay(DateTime.now()));
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
      title: Text('Agenda'),
    );
  }

  Widget _buildFloatingActionButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
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
          locale: 'es_ES',
          headerStyle: HeaderStyle(titleCentered: true, formatButtonVisible: false),
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
    showDialog(
      context: context,
      builder: (context) {
        String? categorySelected = categorys.first;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              scrollable: true,
              title: Text("Añadir un evento"),
              content: Column(
                children: [
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
                    if (_selectedDay != null) {
                      List<Event> listaAux = _getEventsForDay(_selectedDay!);
                      listaAux.add(Event(
                        categorySelected!,
                        _eventController.text,
                        selectedTime!,
                      ));
                      events[_selectedDay!] = listaAux;
                      _selectedEvents.value = listaAux;
                    } else {
                      events.addAll({
                        _selectedDay!: [Event(
                          categorySelected!,
                          _eventController.text,
                          selectedTime!,
                        )]
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
                      final eventsForDay = _getEventsForDay(_selectedDay ?? DateTime.now());
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
                            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              onTap: () {
                                print("Tapped item $eventIndex: ${event.title}");
                              },
                              title: Text('${startTime.hour}:${startTime.minute}    ${event.title}'),
                              subtitle: Text(description),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      _editEvent(event);
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
        _selectedEvents.value = _getEventsForDay(_selectedDay ?? DateTime.now());
      });
    }

    _openDialogs.add(context);
  }

  void _editEvent(Event event) {
    String eventTitle = event.title;
    String eventDescription = event.description;
    TimeOfDay selectedTime = event.time;

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
                  onPressed: () {
                    final editedEvent = Event(eventTitle, _eventController.text, selectedTime);
                    final selectedDay = _selectedDay ?? DateTime.now();
                    final eventsForDay = _getEventsForDay(selectedDay);
                    final index = eventsForDay.indexWhere((e) => e == event);
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
              onPressed: () {
                _performEventDeletion(event);
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
}
