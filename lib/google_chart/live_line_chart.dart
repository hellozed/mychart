import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:mychart/bluetooth/ble.dart';
import 'dart:async';

/* ----------------------------------------------------------------------------
 * Build a dynamic linear chart 
 * 
 * code reference:
 * https://medium.com/flutter/beautiful-animated-charts-for-flutter-164940780b8c
 *
 * alternative chart library is fl_chart, the GUI is more beautiful,
 * but the speed is slower. 
 * https://github.com/imaNNeoFighT/fl_chart/blob/master/example/lib/line_chart/samples/line_chart_sample1.dart
 * 
 * ----------------------------------------------------------------------------*/

//----------------------------------
// stream
//----------------------------------
const initSampleNum = 100;
const animateFlag = false; //turn on the chart animate

/// Sample linear data type.
class ChartData {
  int x;
  int y;
  ChartData(this.x, this.y);
}

StreamController<List<int>> ppgStreamController;
List<ChartData> liveChartData = [];

StreamBuilder<List<int>> installStreamBuilder() {
  // create initial data samples
  int times = initSampleNum;
  // clear all data, because page could be re-entered
  liveChartData.clear();
  ppgStreamController = new StreamController();

  do {
    liveChartData.add(ChartData(liveChartData.length, 0));
    times--;
  } while (times > 0);

  return StreamBuilder(
      stream: ppgStreamController.stream,
      initialData: [],
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        series1 = [
          charts.Series<ChartData, int>(
            id: 'ChartData',
            colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
            measureFn: (ChartData sales, _) => sales.y,
            domainFn: (ChartData sales, _) => sales.x,
            data: liveChartData,
          ),
        ];
        if (snapshot.data != null)
          updateGraph(
              snapshot.data, ppg2, ppg_tx_size * 2 + 2, "ppg", liveChartData);
        return new Padding(
          padding: EdgeInsets.all(32.0),
          child: SizedBox(
            height: 200.0,
            child: charts.LineChart(
              series1, animate: animateFlag,
              /*behaviors: [new charts.PanAndZoomBehavior(),]*/ //turn on the pan znd zoom feature
            ),
          ),
        );
      });
}
//----------------------------------
//
//----------------------------------

class LiveLineChart extends StatefulWidget {
  @override
  _LiveLineChartState createState() => _LiveLineChartState();
}

List<charts.Series<ChartData, num>> series1 = [];

class _LiveLineChartState extends State<LiveLineChart> {
  @override
  void dispose() {
    ppgStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            installStreamBuilder(), // return a StreamBuilder
          ],
        ),
      ),
    );
  }
}
