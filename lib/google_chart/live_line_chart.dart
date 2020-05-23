
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'dart:math';   //for random()
import 'dart:async';  //for Timer()
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

 void generateChartData(){
      if (data1.length>0){
        print('add one chart sample.');
        data1.removeAt(0);
        // each x decrese by 1 to shift the chart left
        data1.forEach((element) {element.x--;});  
        // add one time at the end of the right side
        data1.add(ChartData(data1.length, Random().nextInt(100)));  
      }
      else 
        print('data1 = 0');
  }

class _LiveLineChartState extends State<LiveLineChart> {
 
  List<charts.Series<ChartData, num>> series1 = [];

  // initialize the chart data 
  _LiveLineChartState(){
    // create initial data samples
    int times = initSampleNum;
     do{
      data1.add(ChartData(data1.length, Random().nextInt(100)));
      times--;
    } while (times>0);
  }
 
  void _buttonPressed(){
      setState(() {
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
    var chart1 = charts.LineChart(series1, animate: animateFlag);
    var chartWidget1 = Padding(
          padding: EdgeInsets.all(32.0),
          child: SizedBox(
            height: 200.0,
            child: chart1,
          ),
      );
    // ** End ** : These variables must stay in "Widget build" in order to make a dynamic chart

    
    // Start the periodic timer which prints something every 1 seconds
    Timer.periodic(Duration(milliseconds: 500), (timer) {
      _buttonPressed();
    });
  
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


