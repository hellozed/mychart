import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;

import 'bluetooth.dart';
import 'line_chart/line_chart_page1.dart';
import 'line_chart/line_chart_page2.dart';
import 'line_chart/line_chart_page3.dart';
/* ----------------------------------------------------------------------------
 *  
 *  
 * ----------------------------------------------------------------------------*/
void main() {
  debugPaintSizeEnabled = false;  //Turn this to True if you need debug GUI layout
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),

      body: PageView(
              children: <Widget>[
                LineChartPage(),
                LineChartPage2(),
                LineChartPage3(),
                FlutterBlueApp(),
              ],
            ),
    );
  }
}
