import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'login.dart';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../utils.dart';
class Home extends StatefulWidget {
  @override
  _TableRangeExampleState createState() => _TableRangeExampleState();
}

class _TableRangeExampleState extends State<Home> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode
      .toggledOn; // Can be toggled on/off by longpressing a date
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  Map<DateTime, List<Event>> events={};
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
      appBar: AppBar(
        title: Text('Agenda'),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
                onPressed: () {
                  _eventController.clear();
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          scrollable:true,
                          title: Text("Añadir un evento"),
                          content: Padding(
                            padding: EdgeInsets.all(8),
                            child: TextField(
                              controller: _eventController,
                            ),
                          ),
                          actions: [
                            ElevatedButton(
                                onPressed: (){
                                  if (_selectedDay != null) {
                                    List<Event> listaAux = _getEventsForDay(_selectedDay!);
                                    listaAux.add(Event(_eventController.text));
                                    events[_selectedDay!] = listaAux;
                                    _selectedEvents.value = listaAux;
                                  }else{
                                    events.addAll({
                                      _selectedDay!: [Event(_eventController.text)]
                                    });
                                    _selectedEvents.value=_getEventsForDay(_selectedDay!);
                                  }
                                  Navigator.of(context).pop();
                                },
                                child: Text("Agregar")
                            )
                          ],
                        );
                      });
                },child: Icon(Icons.add)),
            SizedBox(width: 16),
            FloatingActionButton(
                onPressed: () {
                  _eventController.clear();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        scrollable: true,
                        title: Text("Eventos del día"),
                        content: Container(
                          width: 300, // Tamaño personalizado
                          height: 400, // Tamaño personalizado
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: ValueListenableBuilder<List<Event>>(
                                  valueListenable: _selectedEvents,
                                  builder: (context, value, _) {
                                    return ListView.builder(
                                      itemCount: value.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            border: Border.all(),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: ListTile(
                                            onTap: () {
                                              print("Tapped item $index");
                                            },
                                            title: Text('${value[index]}'),
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
                },child: Icon(Icons.search))
          ],
      )

      ,
      body: Column(
        children: [
          TableCalendar(
            firstDay: kFirstDay,
            lastDay: kLastDay,
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            rangeStartDay: _rangeStart,
            rangeEndDay: _rangeEnd,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: _rangeSelectionMode,
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _rangeStart = null; // Important to clean those
                  _rangeEnd = null;
                  _rangeSelectionMode = RangeSelectionMode.toggledOff;
                  _selectedEvents.value = _getEventsForDay(selectedDay);
                });
              }
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
        ],
      )
    );
  }

  List<Event> _getEventsForDay(DateTime day){
    return events[day]??[];
  }
}