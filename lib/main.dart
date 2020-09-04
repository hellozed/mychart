import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:device_info/device_info.dart';
import 'dart:io' show Platform;

//import 'bluetooth/bluetooth.dart';

import 'google_chart/dash_pattern.dart';
import 'google_chart/time_simple.dart';
import 'google_chart/live_line_chart.dart';
import 'bluetooth/ble.dart';
//import 'main1.dart';
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

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    printOsInfo(); // print system information to debug port

    return MaterialApp(
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
        title: Text(widget.title),
      ),
      body: PageView(
        children: <Widget>[
          //FlutterBlueApp(),
          //ConfigPage(),
          LiveLineChart(),
          DashPatternLineChart.withRandomData(),
          SimpleTimeSeriesChart.withRandomData(),
        ],
      ),
    );
  }

  //------------------------------------------
  // code below for monitoring app running state
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
