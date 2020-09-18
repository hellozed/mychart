import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:device_info/device_info.dart';
import 'dart:io' show Platform;
import 'bluetooth/ble.dart';
import 'history.dart';
import 'package:event_bus/event_bus.dart';
import 'home.dart';
import 'file.dart';

//import 'google_chart/time_simple.dart';
//import 'config.dart';

/* ----------------------------------------------------------------------------
 *  
 *  
 * ----------------------------------------------------------------------------*/
void main() {
  debugPaintSizeEnabled =
      false; //Turn this to True if you need debug GUI layout
  runApp(MyApp());
}

// used by page navigator without context
final GlobalKey<NavigatorState> navigatorKey = new GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    printOsInfo(); // print system information to debug port
    bleInitState(); // init bluetooth low engergy
    chartLog.init();// init the file r/w

    return MaterialApp(
      debugShowCheckedModeBanner: false, //disable DEBUG mode banner
      navigatorKey: navigatorKey,
      routes: {
        'home': (context) => LiveLineChart(title: 'Home ICU'),
        'history': (context) => HistoryChart(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
          
        // default brightness and colors
        brightness: Brightness.dark,
        primaryColor: Colors.lightBlue[800],
        accentColor: Colors.cyan[600],

        // default font family
        fontFamily: 'Roboto',

        // default TextTheme
        textTheme: TextTheme(
          headline1: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),

          // used as big screen text  
          headline4: TextStyle(fontSize: 45.0, color: Color(0xFF3dbd2e),fontWeight: FontWeight.w600),
          // used as small screen text  
          headline5: TextStyle(fontSize: 18.0, color: Color(0xFF3dbd2e),fontWeight: FontWeight.w600),
          // used as screen title
          headline6: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),

          //bodyText1: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),

        ),

      ),
      home: LiveLineChart(title: 'Home ICU'),
    );
  }
}

//with conetxt, use Navigator.pushNamed(context, 'nameRoute');

navigatorToHomePage() async {
  navigatorKey.currentState.pop();
  await navigatorKey.currentState.pushReplacementNamed('home');

  //pushReplacementNamed will trigger dispose() than pushNamed
}

navigatorToHistoryPage() async {
  await navigatorKey.currentState.pushNamed('history');

  
}

//------------------------------------------
// print system info to debug
//------------------------------------------
String deviceName;
void printOsInfo() async {
  if (Platform.isAndroid) {
    var androidInfo = await DeviceInfoPlugin().androidInfo;
    var release = androidInfo.version.release;
    var sdkInt = androidInfo.version.sdkInt;
    var manufacturer = androidInfo.manufacturer;
    var model = androidInfo.model;
    print('''Platform information
      Android release: $release 
      SDK: $sdkInt
      Manufacturer: $manufacturer 
      Model: $model''');
  }

  if (Platform.isIOS) {
    var iosInfo = await DeviceInfoPlugin().iosInfo;
    var systemName = iosInfo.systemName;
    var version = iosInfo.systemVersion;
    var name = iosInfo.name;
    var model = iosInfo.model;
    print('''Platform information
      System name: $systemName
      Version: $version
      Name: $name 
      Model: $model''');

    deviceName = name;
  }
}

//------------------------------------------
// event bus
//
// 1. define a event id
// 2. install a lisener
// 3. fire a event with id
//------------------------------------------
EventBus eventBus = EventBus(); // create an Event Bus

enum MyEventId {
  bluetoothOff,
}

class MySystemEvent {
  MyEventId id;
  MySystemEvent(this.id);
}

// install a event listener, when the expected event id received,
// then call the event processing function.

void installEventListener(MyEventId id, void Function() eventProcessing) {
  // register system event listeners
  eventBus.on<MySystemEvent>().listen((event) {
    print(event.id);
    if (event.id == id) eventProcessing();
  });
}

// call this function to fire an event,
void fireEvent(MyEventId id) {
  eventBus.fire(MySystemEvent(id));
}
