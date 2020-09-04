import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;
import 'package:device_info/device_info.dart';
import 'dart:io' show Platform;

//import 'bluetooth/bluetooth.dart';
import 'line_chart/line_chart_page1.dart';
import 'line_chart/line_chart_page3.dart';

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
    return MaterialApp(
      title: 'MyChart',
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
class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {

    printOsInfo(); // print system information to debug port
    
    bleInitState(); // init bluetooth low engergy

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: PageView(
        children: <Widget>[
          //FlutterBlueApp(),
          //ConfigPage(),
          LineChartPage1(),
          LineChartPage3(),
          LiveLineChart(),
          DashPatternLineChart.withRandomData(),
          SimpleTimeSeriesChart.withRandomData(),
        ],
      ),
    );
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
