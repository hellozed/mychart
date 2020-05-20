import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show debugPaintSizeEnabled;

import 'bluetooth.dart';
import 'line_chart/line_chart_page1.dart';
import 'line_chart/line_chart_page2.dart';
import 'line_chart/line_chart_page3.dart';


import 'google_chart/animation_zoom.dart';            
import 'google_chart/area_and_line.dart';             
import 'google_chart/range_annotation.dart';
import 'google_chart/dash_pattern.dart';              
import 'google_chart/simple.dart';
import 'google_chart/line_annotation.dart';           
import 'google_chart/time_simple.dart';


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
                
                LineAnimationZoomChart.withRandomData(),
                AreaAndLineChart.withRandomData(),
                LineRangeAnnotationChart.withRandomData(),
                DashPatternLineChart.withRandomData(),
                LineLineAnnotationChart.withRandomData(),
                SimpleLineChart.withRandomData(),


                SimpleTimeSeriesChart.withRandomData(),
                
                LineChartPage1(),
                LineChartPage2(),
                LineChartPage3(),
                FlutterBlueApp(),
                
              ],
            ),
    );
  }
}
