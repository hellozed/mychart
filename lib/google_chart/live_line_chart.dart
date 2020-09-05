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
const ChartDataSize = 100;
const animateFlag = false; //turn on the chart animate

/// Sample linear data type.
class ChartData {
  int x;
  int y;
  ChartData(this.x, this.y);
}

StreamController<List<int>> ppgStreamController, ecgStreamController;
List<ChartData> ppgChartData = [], ecgChartData = [];

enum DataSource{ppg, ecg}

StreamBuilder<List<int>> installStreamBuilder(DataSource dataSource) {
  List<charts.Series<ChartData, num>> series1 = [];

  // clear all data, because page could be re-entered
  if (dataSource == DataSource.ppg)
  {
    ppgStreamController = new StreamController();
    ppgChartData.clear();
    // create initial data samples
    for (int i = 0; i < ChartDataSize; i++) 
        ppgChartData.add(ChartData(i, 0));
  }
  else
  {
    ecgStreamController = new StreamController();
    ecgChartData.clear();
    // create initial data samples
    for (int i = 0; i < ChartDataSize; i++) 
      ecgChartData.add(ChartData(i, 0));
  }
  
  return StreamBuilder(
      stream: (dataSource == DataSource.ppg)?
              ppgStreamController.stream :ecgStreamController.stream,
      initialData: [],
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        series1 = [
          charts.Series<ChartData, int>(
            id: 'ChartData',
            colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
            measureFn: (ChartData sales, _) => sales.y,
            domainFn: (ChartData sales, _) => sales.x,
            data: (dataSource == DataSource.ppg)
                ? ppgChartData
                : ecgChartData,
          ),
        ];
        if (snapshot.data != null)
          updateGraph(snapshot.data, ppg2, ppg_tx_size * 2 + 2, "ppg",
              (dataSource == DataSource.ppg) ? ppgChartData : ecgChartData);
        return new Padding(
          padding: EdgeInsets.all(32.0),
          child: SizedBox(
            height: 100.0,
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

class _LiveLineChartState extends State<LiveLineChart> {
  @override
  void dispose() {
    ppgStreamController.close();
    ecgStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            installStreamBuilder(DataSource.ppg), // return a StreamBuilder
            installStreamBuilder(DataSource.ecg),
          ],
        ),
      ),
    );
  }
}
