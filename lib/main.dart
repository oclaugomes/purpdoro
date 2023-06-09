import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purpdoro/settings_page.dart';
import 'package:purpdoro/timer_page.dart';

import 'package:audioplayers/audioplayers.dart';

void main() {
  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: "basic_channel",
        channelName: "Basic Notification",
        channelDescription: "Basic notification channel",
      )
    ],
    // debug: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int currentPage = 0;
  late PageController pageController;
  var _timers = {
    "work": 25,
    "break": 5,
    "longBreak": 15,
  };
  var _sessionsBeforeLongBreak = 4;
  var _paused = true;
  var _currentSession = 1;
  int _remaining = 25 * 60;
  Timer? _timer;

  final alarmAudioPlayer = AudioPlayer();

  @override
  void initState() {
    pageController = PageController(initialPage: currentPage);
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    super.initState();
  }

  _playAlarmSound() async {
    await alarmAudioPlayer
        .setSource(AssetSource("sounds/alarm.mp3"))
        .then((value) {
      alarmAudioPlayer.resume();
    });
  }

  String _getSessionName() {
    if (_currentSession % 2 == 0 &&
        _currentSession < _sessionsBeforeLongBreak * 2) {
      return "Break";
    } else if (_currentSession == _sessionsBeforeLongBreak * 2) {
      return "Long Break";
    } else {
      return "Work";
    }
  }

  _getAlarmNotification() {
    _playAlarmSound();
    var sessionName = _getSessionName();
    if (sessionName == "Work") {
      AwesomeNotifications().createNotification(
          content: NotificationContent(
        id: 1,
        channelKey: "basic_channel",
        title: "Time to work!",
        body: "Let's get to work!",
        displayOnBackground: true,
        displayOnForeground: true,
        wakeUpScreen: true,
      ));
    } else {
      AwesomeNotifications().createNotification(
          content: NotificationContent(
        id: 2,
        channelKey: "basic_channel",
        title: "Take a $sessionName!",
        body: "Chill out for a while. Maybe drink some water.",
        displayOnBackground: true,
        displayOnForeground: true,
        wakeUpScreen: true,
      ));
    }
  }

  _toggleTimer() {
    if (_paused || !_timer!.isActive) {
      setState(() {
        _paused = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
        if (_remaining == 0) {
          _skipSession();
          _getAlarmNotification();
        } else {
          setState(() {
            _remaining--;
          });
        }
      });
    } else {
      _timer!.cancel();
      setState(() {
        _paused = true;
      });
    }
  }

  _skipSession() {
    setState(() {
      if (_currentSession + 1 == _sessionsBeforeLongBreak * 2) {
        _currentSession += 1;
        _remaining = _timers["longBreak"]! * 60;
      } else if (_currentSession == _sessionsBeforeLongBreak * 2) {
        _currentSession = 1;
        _remaining = _timers["work"]! * 60;
      } else if (_currentSession == _sessionsBeforeLongBreak * 2 ||
          _currentSession % 2 == 0) {
        _currentSession += 1;
        _remaining = _timers["work"]! * 60;
      } else {
        _currentSession += 1;
        _remaining = _timers["break"]! * 60;
      }
    });
  }

  _reset() {
    setState(() {
      _currentSession = 1;
      _remaining = _timers["work"]! * 60;
      _paused = true;
      if (_timer != null && _timer!.isActive) {
        _timer!.cancel();
      }
    });
  }

  _setCurrentPage(page) {
    setState(() {
      currentPage = page;
    });
  }

  _setTimers(newTimers) {
    setState(() {
      _timers = newTimers;
    });
    _reset();
  }

  _setSessionsBeforeLongBreak(newValue) {
    setState(() {
      _sessionsBeforeLongBreak = newValue;
    });
    _reset();
  }

  @override
  Widget build(BuildContext context) {
    // debugPaintSizeEnabled = true
    return MaterialApp(
        title: "Purpdoro",
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.deepPurple,
              accentColor: Colors.deepPurple[400]),
        ),
        home: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: currentPage,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.timer_rounded),
                label: "Timer",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: "Settings",
              )
            ],
            onTap: (page) {
              pageController.animateToPage(page,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
            backgroundColor: Colors.deepPurple,
            fixedColor: Colors.white,
            unselectedItemColor: Colors.deepPurple[300],
          ),
          appBar: AppBar(
            systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.deepPurple,
                systemNavigationBarColor: Colors.deepPurple),
            title: const SizedBox(
              width: double.infinity,
              child: Text(
                "Purpdoro",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            backgroundColor: Colors.deepPurple,
            shadowColor: Colors.transparent,
          ),
          body: PageView(
            controller: pageController,
            onPageChanged: _setCurrentPage,
            children: [
              TimerPage(
                paused: _paused,
                timers: _timers,
                sessionsBeforeLongBreak: _sessionsBeforeLongBreak,
                currentSession: _currentSession,
                remaining: _remaining,
                reset: _reset,
                skipSession: _skipSession,
                toggleTimer: _toggleTimer,
                getSessionName: _getSessionName,
              ),
              SettingsPage(
                setTimers: _setTimers,
                timers: _timers,
                sessionsBeforeLongBreak: _sessionsBeforeLongBreak,
                setSessionsBeforeLongBreak: _setSessionsBeforeLongBreak,
              ),
            ],
          ),
        ));
  }
}
