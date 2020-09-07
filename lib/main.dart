import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:device_info/device_info.dart';
import 'dart:io' show Platform;
import 'google_chart/dash_pattern.dart';
import 'google_chart/time_simple.dart';
import 'google_chart/live_line_chart.dart';
import 'bluetooth/ble.dart';
import 'config.dart';
import 'package:event_bus/event_bus.dart';
/* ----------------------------------------------------------------------------
 *  
 *  
 * ----------------------------------------------------------------------------*/
void main() {
  debugPaintSizeEnabled =
      false; //Turn this to True if you need debug GUI layout
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    printOsInfo(); // print system information to debug port

    return MaterialApp(
      debugShowCheckedModeBanner: false, //disable DEBUG mode banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Home ICU'),
    );
  }
}

/* ----------------------------------------------------------------------------
 *  
 *  
 * ----------------------------------------------------------------------------*/
class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

/* ----------------------------------------------------------------------------
 *  
 *  
 * ----------------------------------------------------------------------------*/
class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    bleInitState(); // init bluetooth low engergy

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontSize: 18.0,
          ),
        ),
        leading: Icon(Icons.menu),
        actions: <Widget>[
          IconButton(icon: Icon(Icons.account_circle), onPressed: () => { })
        ]
      ),

      body: PageView(
        // install multiple pages
        children: <Widget>[
          //FlutterBlueApp(),
          LiveLineChart(),
          DashPatternLineChart.withRandomData(),
          SimpleTimeSeriesChart.withRandomData(),
          ConfigPage(),
        ],
      ),
    );
  }

  //------------------------------------------
  // code for monitoring app running state
  //------------------------------------------
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");
        bleInitState();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        print("app in inactive or paused");
        bleStopScan();
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
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
    if (event.id ==id)
      eventProcessing();
  });
}
  
// call this function to fire an event,
void fireEvent(MyEventId id) {
  eventBus.fire(MySystemEvent(id));
}
