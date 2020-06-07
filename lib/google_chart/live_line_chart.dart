
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'dart:math';   //for random()
import 'dart:async';  //for Timer()
import 'package:mychart/bluetooth/ble.dart';
/* ----------------------------------------------------------------------------
 * Build a dynamic linear chart 
 * code reference:
 * https://medium.com/flutter/beautiful-animated-charts-for-flutter-164940780b8c
 * ----------------------------------------------------------------------------*/
const initSampleNum = 100;
const animateFlag = false;    //turn on the chart animate

/// Sample linear data type.
class ChartData {
  int x;
  int y;
  ChartData(this.x, this.y);
}


class LiveLineChart extends StatefulWidget {
  @override
  _LiveLineChartState createState() => _LiveLineChartState();

 
}
List <ChartData> data1 = [];

class _LiveLineChartState extends State<LiveLineChart> {
 
  List<charts.Series<ChartData, num>> series1 = [];

  // initialize the chart data 
  _LiveLineChartState(){
    // create initial data samples
    int times = initSampleNum;
    // clear all data, because page could be re-entered
    data1.clear();
     do{
      data1.add(ChartData(data1.length, Random().nextInt(100)));
      times--;
    } while (times>0);

    bleTest();//test

    Timer.periodic(Duration(milliseconds: 500), (timer) {
      _buttonPressed();
    });
    
  }
 
  void _buttonPressed(){

      // do not call setState if app switch to another page
      // just in case this function called by a timer
      if (this.mounted==false){  
        //if (timer.isActive)
        //  timer.cancel();
        return;
      }
      this.setState(() {
          // remove the first data point on the left  
          data1.removeAt(0);

          // each x decrese by 1 to shift the chart left
          data1.forEach((element) {element.x--;});  
          
          // add one time at the end of the right side
          data1.add(ChartData(data1.length, Random().nextInt(100)));  
        });
    }
  @override
  Widget build(BuildContext context) {
    // ** Begin ** : These variables must stay in "Widget build" in order to make a dynamic chart
    series1 = [
            charts.Series <ChartData, int> (
            id: 'ChartData',
            colorFn:   (_, __) => charts.MaterialPalette.blue.shadeDefault,
            measureFn: (ChartData sales, _) => sales.y,
            domainFn:  (ChartData sales, _) => sales.x,
            data: data1,
          ),
        ];
    var chart1 = charts.LineChart(
      series1, 
      animate: animateFlag,
      /*behaviors: [new charts.PanAndZoomBehavior(),]*/  //turn on the pan znd zoom feature
      );
    
    var chartWidget1 = Padding(
          padding: EdgeInsets.all(32.0),
          child: SizedBox(
            height: 200.0,
            child: chart1,
          ),
      );
    // ** End ** : These variables must stay in "Widget build" in order to make a dynamic chart
    
    // Start the periodic timer which prints something every 1 seconds
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            chartWidget1,
          ],
        ),
      ),
        
      floatingActionButton: FloatingActionButton(
        onPressed: _buttonPressed,
        tooltip: 'Test',
        child: Icon(Icons.add),
      ),
    );
  }
}


