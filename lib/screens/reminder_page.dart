import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';

class ReminderPage extends StatefulWidget {
  final String userId;
  final bool haveReminders;

  const ReminderPage(
      {super.key, required this.userId, required this.haveReminders});

  @override
  _ReminderPageState createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final CollectionReference remindersCollection =
      FirebaseFirestore.instance.collection('reminders');
  final CollectionReference usersCollection =
      FirebaseFirestore.instance.collection('users');

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          defaultPrivacy: NotificationPrivacy.Private,
        ),
      ],
      debug: true,
    );
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await _checkNotificationPermission();
    await _checkExactAlarmPermission();
  }

  Future<void> _checkNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  Future<void> _checkExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isGranted) {
    } else {
      if (await Permission.scheduleExactAlarm.request().isGranted) {
      } else {
      }
    }
  }

  Future<void> _scheduleNotification(
      ReminderModel reminder, String frequency) async {
    final location = tz.getLocation('Asia/Kolkata');
    var scheduledNotificationDateTime =
        tz.TZDateTime.from(reminder.date.toDate(), location);

    NotificationSchedule schedule;
    if (frequency == 'Once') {
      schedule = NotificationCalendar.fromDate(
          date: scheduledNotificationDateTime, allowWhileIdle: true, preciseAlarm: true);
    } else if (frequency == 'Daily') {
      schedule = NotificationCalendar(
        hour: scheduledNotificationDateTime.hour,
        minute: scheduledNotificationDateTime.minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
      );
    } else if (frequency == 'Weekly') {
      schedule = NotificationCalendar(
        weekday: scheduledNotificationDateTime.weekday,
        hour: scheduledNotificationDateTime.hour,
        minute: scheduledNotificationDateTime.minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
      );
    } else if (frequency == 'Monthly') {
      schedule = NotificationCalendar(
        day: scheduledNotificationDateTime.day,
        hour: scheduledNotificationDateTime.hour,
        minute: scheduledNotificationDateTime.minute,
        second: 0,
        repeats: true,
        allowWhileIdle: true,
      );
    } else {
      return;
    }

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: reminder.id.hashCode,
        channelKey: 'basic_channel',
        title: 'Reminder',
        body: reminder.message,
        payload: {
          'reminderId': reminder.id,
          'scheduledTime': scheduledNotificationDateTime.toString(),
        },
      ),
      schedule: schedule,
    );
  }

  Future<void> _addReminder(ReminderModel reminder, String frequency) async {
    reminder.frequency = frequency;
    DocumentReference docRef =
    await remindersCollection.add(reminder.toDocument());
    reminder.id = docRef.id;
    await _scheduleNotification(reminder, frequency);
    if (!widget.haveReminders) {
      await usersCollection.doc(widget.userId).update({'haveReminders': true});
    }
    setState(() {});
  }

  Future<void> _autoDeleteExpiredReminders(List<ReminderModel> reminders) async {
    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    for (var reminder in reminders) {
      DateTime reminderDate = reminder.date.toDate();

      if (reminder.frequency == 'Once' &&
          reminderDate.isBefore(now) &&
          reminderDate.isBefore(DateTime.now())) {
        await remindersCollection.doc(reminder.id).delete();
        await AwesomeNotifications()
            .cancelSchedule(reminder.id.hashCode);
        final remindersSnapshot = await remindersCollection
            .where('userId', isEqualTo: widget.userId).limit(1)
            .get();
        if (remindersSnapshot.docs.isEmpty) {
          await usersCollection
              .doc(widget.userId)
              .update({'haveReminders': false});
        }
        setState(() {});
      } else if (reminder.frequency != 'Once' && reminderDate.isBefore(sixMonthsAgo)) {
        await remindersCollection.doc(reminder.id).delete();
        await AwesomeNotifications()
            .cancelSchedule(reminder.id.hashCode);
        final remindersSnapshot = await remindersCollection
            .where('userId', isEqualTo: widget.userId).limit(1)
            .get();
        if (remindersSnapshot.docs.isEmpty) {
          await usersCollection
              .doc(widget.userId)
              .update({'haveReminders': false});
        }
        setState(() {});
      }
    }
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    await _showDeleteConfirmationDialog(reminder);
  }

  Future<void> _showDeleteConfirmationDialog(ReminderModel reminder) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Reminder',
            style: TextStyle(color: Colors.orange),
          ),
          content: const Text(
            'Are you sure you want to delete this reminder?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.orange),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.orange),
              ),
              onPressed: () async {
                await remindersCollection.doc(reminder.id).delete();
                await AwesomeNotifications()
                    .cancelSchedule(reminder.id.hashCode);
                final remindersSnapshot = await remindersCollection
                    .where('userId', isEqualTo: widget.userId).limit(1)
                    .get();
                if (remindersSnapshot.docs.isEmpty) {
                  await usersCollection
                      .doc(widget.userId)
                      .update({'haveReminders': false});
                }
                setState(() {});
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      },
    );
  }

  void _showAddReminderDialog() {
    String message = '';
    String errorMessage = '';
    DateTime selectedDate = DateTime.now();
    DateTime selectedTime = DateTime.now();
    String frequency = 'Once';

    showDialog(
      useSafeArea: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFDFFE2B3),
              title: const Text(
                'Add Reminder',
                style: TextStyle(color: Color(0xFFEF6C06)),
              ),
              content: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: const Color(0xFFFCE5D3)
                      .withOpacity(0.75), // Light orange background tint
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                            labelText: 'Message',
                            labelStyle: TextStyle(fontSize: 18)),
                        onChanged: (value) {
                          message = value;
                        },
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        children: [
                          Text(
                            frequency == 'Once' ? 'Date:' : 'Start Date:',
                            style: const TextStyle(
                                fontSize: 20, color: Color(0xFFEF6C06)),
                          ),
                          const SizedBox(width: 8.0),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  selectedDate = pickedDate;
                                  selectedTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    selectedTime.hour,
                                    selectedTime.minute,
                                  );
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Text(
                                  "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8.0),
                                const Icon(
                                  Icons.calendar_month_sharp,
                                  color: Color(0xFFEF6C06),
                                  size: 24.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Row(
                        children: [
                          const Text(
                            'Time:',
                            style: TextStyle(
                                fontSize: 20, color: Color(0xFFEF6C06)),
                          ),
                          const SizedBox(width: 8.0),
                          GestureDetector(
                            onTap: () async {
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                context: context,
                                initialTime:
                                    TimeOfDay.fromDateTime(selectedTime),
                              );
                              if (pickedTime != null) {
                                setState(() {
                                  selectedTime = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Text(
                                  "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 8.0),
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFFEF6C06),
                                  size: 24.0,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15.0),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE5D3),
                          border: Border.all(color: Colors.orange, width: 2),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: frequency,
                            items: ['Once', 'Daily', 'Weekly', 'Monthly']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                frequency = newValue!;
                              });
                            },
                            dropdownColor: const Color(0xFFFCE5D3),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: frequency != 'Once',
                        child: const Column(
                          children: [
                            SizedBox(height: 15.0),
                            Text(
                              'Note: Scheduled reminders will be deleted after 6 months.',
                              style: TextStyle(
                                  color: Color(0xFFEF6C06), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: errorMessage.isNotEmpty,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 14.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFFEF6C06)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text(
                    'Add',
                    style: TextStyle(color: Color(0xFFEF6C06)),
                  ),
                  onPressed: () async {
                    if (message.trim().isEmpty) {
                      setState(() {
                        errorMessage = "Message cannot be empty.";
                      });
                      return;
                    }
                    if (message.trim().length > 25) {
                      setState(() {
                        errorMessage = "Message is too large.";
                      });
                      return;
                    }
                    DateTime currentTime = DateTime.now();
                    if (selectedTime.isBefore(currentTime)) {
                      setState(() {
                        errorMessage = "Date and time must be in the future.";
                      });
                      return;
                    }
                    final remindersSnapshot = await remindersCollection
                        .where('userId', isEqualTo: widget.userId)
                        .where('date', isEqualTo: Timestamp.fromDate(selectedTime))
                        .get();
                    if (remindersSnapshot.docs.isNotEmpty) {
                      for (var doc in remindersSnapshot.docs) {
                        var existingReminder = ReminderModel.fromDocument(doc);

                        if (frequency == 'Once') {
                          if (existingReminder.date.toDate().isAtSameMomentAs(selectedTime)) {
                            setState(() {
                              errorMessage = "Reminder already exists";
                            });
                            break;
                          }
                        } else if (frequency == 'Daily') {
                          if (existingReminder.date.toDate().isBefore(selectedTime) ||
                              existingReminder.date.toDate().isAtSameMomentAs(selectedTime)) {
                            setState(() {
                              errorMessage = "Reminder already exists";
                            });
                            break;
                          }
                        } else if (frequency == 'Weekly') {
                          if (existingReminder.date.toDate().isBefore(selectedTime) ||
                              existingReminder.date.toDate().isAtSameMomentAs(selectedTime) && existingReminder.date.toDate().weekday == selectedTime.weekday) {
                            setState(() {
                              errorMessage = "Reminder already exists";
                            });
                            break;
                          }
                        } else if (frequency == 'Monthly') {
                          if (existingReminder.date.toDate().isBefore(selectedTime) ||
                              existingReminder.date.toDate().isAtSameMomentAs(selectedTime) && existingReminder.date.toDate().day == selectedTime.day) {
                            setState(() {
                              errorMessage = "Reminder already exists.";
                            });
                            break;
                          }
                        }
                      }
                      return;
                    }
                    ReminderModel newReminder = ReminderModel(
                      id: '',
                      userId: widget.userId,
                      message: message,
                      date: Timestamp.fromDate(selectedTime),
                      frequency: frequency,
                    );

                    _addReminder(newReminder, frequency);

                    Navigator.of(context).pop();
                  },
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: StreamBuilder<QuerySnapshot>(
        stream: remindersCollection
            .where('userId', isEqualTo: widget.userId)
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF6C06)),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No Reminders',
                style: TextStyle(fontSize: 20),
              ),
            );
          }

          List<ReminderModel> reminders = snapshot.data!.docs.map((doc) {
            return ReminderModel.fromDocument(doc);
          }).toList();

          // Call auto-delete for expired reminders
          _autoDeleteExpiredReminders(reminders);

          // Separate 'Once' reminders and others
          List<ReminderModel> onceReminders = reminders
              .where((reminder) => reminder.frequency == 'Once')
              .toList();
          List<ReminderModel> otherReminders = reminders
              .where((reminder) => reminder.frequency != 'Once')
              .toList();

          return ListView.builder(
            itemCount: onceReminders.length + otherReminders.length,
            itemBuilder: (context, index) {
              ReminderModel reminder;
              if (index < onceReminders.length) {
                reminder = onceReminders[index];
              } else {
                reminder = otherReminders[index - onceReminders.length];
              }
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(reminder.date.toDate());

              return Card(
                margin: const EdgeInsets.fromLTRB(12, 18, 12, 0),
                color: const Color(0xFFFCDBC2),
                child: ListTile(
                  title: Text(reminder.message),
                  titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.black),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('$formattedDate | ${reminder.frequency}'),
                  ),
                  subtitleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w200, color: Colors.black),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      _deleteReminder(reminder);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 23.0, right: 10.0),
        child: FloatingActionButton.extended(
          onPressed: _showAddReminderDialog,
          backgroundColor: const Color(0xE4FAB118),
          elevation: 4.0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12.0)),
          ),
          icon: const Icon(
            Icons.more_time_outlined,
            color: Colors.white, // White icon for readability
          ),
          label: const Text(
            'Reminder',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
