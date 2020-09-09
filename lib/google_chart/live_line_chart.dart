import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:mychart/bluetooth/ble.dart';
import 'dart:async';
import '../main.dart';

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

const mainBackgroundColor = Colors.black;

//----------------------------------
// page
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
    numStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    installEventListener(MyEventId.bluetoothOff, showBluetoothOffDialog);

    return Scaffold(
      body: Center(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              //left column
              Expanded(
                flex: 2,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      myChartBlock(DataSource.ecg, "ECG", 1),
                      myChartBlock(DataSource.ppg, "PPG", 1),
                    ]),
              ),

              //right column

              numStreamBuilder(),
            ]),
      ),
    );
  }

  // dialog
  Future<bool> showBluetoothOffDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Waiting"),
          content: Text("Bluetooth is OFF, please turn it on!"),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(true); //close it, return true
              },
            ),
          ],
        );
      },
    );
  }
}

//----------------------------------
// stream
//----------------------------------
const ppgChartDataSize = 100;
const ecgChartDataSize = 125*4;
const animateFlag = false; //turn on the chart animate

/// Sample linear data type.
class ChartData {
  int x;
  int y;
  ChartData(this.x, this.y);
}

class VitalNumbers {
  int sPo2;
  double temperature;
  int heartRate;
  int battery;
  //hrv
  //hist
  clear() {
    sPo2 = 0;
    temperature = 0;
    heartRate = 0;
    battery = 0;
  }

  VitalNumbers() {
    clear();
  }
}

StreamController<VitalNumbers> numStreamController;
StreamController<List<int>> ppgStreamController, ecgStreamController;
List<ChartData> ppgChartData = [], ecgChartData = [];
enum DataSource { ppg, ecg }

//----------------------------------
// build stream for processing vital number
//----------------------------------
StreamBuilder<VitalNumbers> numStreamBuilder() {

  numStreamController = StreamController();

  return StreamBuilder(
      stream: numStreamController.stream,
      initialData: VitalNumbers(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return Expanded(
          flex: 1,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                
                myTextBlock(snapshot.data.heartRate.toString(), "HR", 15),
                myTextBlock(
                    snapshot.data.temperature.toStringAsFixed(1), "TEMP", 15),
                myTextBlock(snapshot.data.sPo2.toString(), "SpO2", 15),
                myBatteryBlock(snapshot.data.battery.toString(), 4),
              ]),
        );
      });
}

//----------------------------------
// build stream for ecg and ppg
//----------------------------------
StreamBuilder<List<int>> myStreamBuilder(DataSource dataSource) {
  List<charts.Series<ChartData, num>> series1 = [];

  // clear all data, because page could be re-entered
  if (dataSource == DataSource.ppg) {
    ppgStreamController = StreamController();
    ppgChartData.clear();
    // create initial data samples for ppg
    for (int i = 0; i < ppgChartDataSize; i++) ppgChartData.add(ChartData(i, 0));
  } else {
    ecgStreamController = StreamController();
    ecgChartData.clear();
    // create initial data samples for ecg
    for (int i = 0; i < ecgChartDataSize; i++) ecgChartData.add(ChartData(i, 0));
  } 

  return StreamBuilder(
      stream: (dataSource == DataSource.ppg)
          ? ppgStreamController.stream
          : ecgStreamController.stream,
      initialData: [],
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        // do not move this line to the top
        series1 = [
          charts.Series<ChartData, int>(
            id: 'ChartData',
            colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
            measureFn: (ChartData sales, _) => sales.y,
            domainFn: (ChartData sales, _) => sales.x,
            data: (dataSource == DataSource.ppg) ? ppgChartData : ecgChartData,
          ),
        ];
        if (snapshot.data != null)
          updateGraph(snapshot.data, ppg2, ppg_tx_size * 2 + 2, "ppg",
              (dataSource == DataSource.ppg) ? ppgChartData : ecgChartData);
        return Padding(
          padding: EdgeInsets.all(2.0),
          child: charts.LineChart(
            series1, animate: animateFlag,
            /*behaviors: [ charts.PanAndZoomBehavior(),]*/ //turn on the pan znd zoom feature
          ),
        );
      });
}

//----------------------------------
// block for display chart
//----------------------------------
Expanded myChartBlock(DataSource dataSource, String myText, int myFlex) {
  return Expanded(
    flex: myFlex,
    child: Container(
      color: mainBackgroundColor,
      margin: EdgeInsets.all(1.0), //outside
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.centerLeft,

      child: Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[
          //chart
          Positioned(
            child: myStreamBuilder(dataSource), // return a StreamBuilder
          ),

          //text
          Positioned(
            bottom: 25.0,
            right: 10.0,
            child: Text(
              myText.toString(),
              style: TextStyle(
                fontSize: 20.0, 
                color: mySmallTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

//----------------------------------
// block for display text block
//----------------------------------
// pre-defined theme parameters
const myBigTextColor = Color(0xFF3dbd2e);
const mySmallTextColor = Color(0xFF3dbd2e);

Expanded myTextBlock(String bigText, String smallText, int myFlex) {
  return Expanded(
    flex: myFlex,
    child: Container(
      color: mainBackgroundColor,
      margin: EdgeInsets.all(1.0), //outside
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,

      child: Stack(
        alignment: Alignment.center,
        overflow: Overflow.visible,
        fit: StackFit.expand,
        children: <Widget>[
          //big text
          Positioned(
            top: 25,
            left: 8,
            child: Text(
              bigText.toString(),
              style: TextStyle(
                fontSize: 45,
                color: myBigTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          //small text
          Positioned(
            bottom: 5,
            right: 5,
            child: Text(
              smallText.toString(),
              style: TextStyle(
                fontSize: 25,
                color: mySmallTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Expanded myBatteryBlock(String bigText, int myFlex) {
  return Expanded(
    flex: myFlex,
    child: Container(
      color: mainBackgroundColor,
      margin: EdgeInsets.all(1.0), //outside
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,

      child: Stack(
        alignment: Alignment.centerLeft,
        overflow: Overflow.visible,
        fit: StackFit.expand,
        children: <Widget>[
          //big text
          Positioned(
            left: 5,
            child: Text(
              (bigText+"%").toString(),
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          //small text
          Positioned(
            right: 5,
            child: RotatedBox(
              quarterTurns: 3,
              child: IconButton(
                icon: Icon(
                  Icons.battery_full,
                  color: Colors.grey,
                ),
                onPressed: null,
              ),
            ),
                        
            ),
          
        ],
      ),
    ),
  );
}