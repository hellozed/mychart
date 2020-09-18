import 'dart:typed_data';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mychart/bluetooth/ble.dart';
import 'dart:async';
import 'main.dart';
import 'file.dart';
/* ----------------------------------------------------------------------------
 * Main screen of the mychart app
 * 
 * receive data from ble, display ecg and ppg chart, and vital signs.
 * 
 * use google dynamic linear chart library.
 * 
 * code reference:
 * https://medium.com/flutter/beautiful-animated-charts-for-flutter-164940780b8c
 *
 * alternative chart library is fl_chart, the GUI is more beautiful,
 * but the speed is slower. 
 * https://github.com/imaNNeoFighT/fl_chart/blob/master/example/lib/line_chart/samples/line_chart_sample1.dart
 * 
 * Tool for generate GUI
 * https://flutterstudio.app
 * ----------------------------------------------------------------------------*/

//data represent each sample point on the linear data type.
class ChartData {
  int x;
  int y;
  ChartData(this.x, this.y);
}

enum DataSource { ppg, ecg }

const mainBackgroundColor = Colors.black;

//----------------------------------
// home page (main app screen)
//----------------------------------
class LiveLineChart extends StatefulWidget {
  LiveLineChart({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _LiveLineChartState createState() => _LiveLineChartState();
}

class _LiveLineChartState extends State<LiveLineChart>
    with WidgetsBindingObserver {
  @override
  Widget build(BuildContext context) {
    installEventListener(MyEventId.bluetoothOff, showBluetoothOffDialog);

    return Scaffold(
      appBar: AppBar(
          // app title
          title: Text(
            widget.title,
            style: Theme.of(context).textTheme.headline6,
          ),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.account_circle), onPressed: () {}),
          ]),
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
                      myChartBlock(
                          DataSource.ecg, "ECG", 1, context), // show ecg chart
                      myChartBlock(
                          DataSource.ppg, "PPG", 1, context), // show ppg chart
                    ]),
              ),

              //right column
              numStreamBuilder(), // show serveral vital sign numbers
            ]),
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Settings'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('Delete History'),
              onTap: () {
                // delete history file of ecg
                chartLog.delete();
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('More Settings'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  //------------------------------------------
  // code for monitoring app running state
  //------------------------------------------
  //@override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        print("app in resumed");
        bleInitState(); // re-establih ble connection when app resumes
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        print("app in inactive or paused");
        bleStopScan(); // stop ble communication when app is not in use
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  void dispose() async {
    // when this page is off, turn off ble streams
    ppgStreamController.close();
    ecgStreamController.close();
    numStreamController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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

//----------------------------------
// stream definations
//----------------------------------
const ppgChartDataSize =
    100; // each ppg chart display so many samples (sample rate 25sps)
const ecgChartDataSize =
    125 * 4; // each ecg chart display so many samples (sample rate 125 sps)

StreamController<VitalNumbers> numStreamController;
StreamController<List<int>> ppgStreamController, ecgStreamController;
List<ChartData> ppgChartData = [], ecgChartData = [];

//----------------------------------
// build a stream for processing vital number
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
                myTextBlock(
                    snapshot.data.heartRate.toString(), "HR", 15, context),
                myTextBlock(snapshot.data.temperature.toStringAsFixed(1),
                    "TEMP", 15, context),
                myTextBlock(snapshot.data.sPo2.toString(), "SpO2", 15, context),
                myBatteryBlock(snapshot.data.battery.toString(), 4, context),
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
    for (int i = 0; i < ppgChartDataSize; i++)
      ppgChartData.add(ChartData(i, 0));
  } else {
    ecgStreamController = StreamController();
    ecgChartData.clear();
    // create initial data samples for ecg
    for (int i = 0; i < ecgChartDataSize; i++)
      ecgChartData.add(ChartData(i, 0));
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
        if (snapshot.data != null) {
          convertToChartData(
              snapshot.data,
              ppg2,
              ppg_tx_size * 2 + 2,
              dataSource,
              (dataSource == DataSource.ppg) ? ppgChartData : ecgChartData);
        }
        return Padding(
          padding: EdgeInsets.all(2.0),
          child: charts.LineChart(
            series1, animate: false, //turn off the chart animate
            /*behaviors: [ charts.PanAndZoomBehavior(),]*/ //turn on the pan znd zoom feature
          ),
        );
      });
}

//----------------------------------
// block for display chart
//----------------------------------
Expanded myChartBlock(
    DataSource dataSource, String myText, int myFlex, BuildContext context) {
  return Expanded(
      flex: myFlex,
      child: GestureDetector(
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
                child: myStreamBuilder(dataSource),
              ),

              //text
              Positioned(
                bottom: 25.0,
                right: 10.0,
                child: Text(
                  myText.toString(),
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
            ],
          ),
        ),
        //onTap: ()=>navigatorToHistoryPage(), this does not work due to "stack"
        onDoubleTap: () => navigatorToHistoryPage(),
        onLongPress: () => navigatorToHistoryPage(),
      ));
}

//----------------------------------
// block for display text block
//----------------------------------

Expanded myTextBlock(
    String bigText, String smallText, int myFlex, BuildContext context) {
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
              style: Theme.of(context).textTheme.headline4,
            ),
          ),

          //small text
          Positioned(
            bottom: 5,
            right: 5,
            child: Text(
              smallText.toString(),
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
        ],
      ),
    ),
  );
}

Expanded myBatteryBlock(String bigText, int myFlex, BuildContext context) {
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
              (bigText + "%").toString(),
              style: Theme.of(context).textTheme.headline5,
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

void convertToChartData(List<int> data, List<int> data2, int len,
    DataSource dataSource, List<ChartData> chartData) {
  if (data.length == 0) return; //received zero data

  if (data.length < len) {
    //data len = pack size + 1 serial number
    print("err: len=${data.length}, byte missing");
    return;
  }

  //skip the same data
  bool isEqual = listEquals<int>(data, data2);
  if (isEqual) return; //receive same data again, ignore it

  data2.clear();
  data2.addAll(data);

  //convet to int16, remove the last item which is the sequence number
  var data8 = new Uint8List.fromList(data);
  List<int> data16 = new List.from(data8.buffer.asInt16List(), growable: true);
  data16.removeLast(); //remove the serial number

  // store stream to chart history file and store in the disk
  if (dataSource == DataSource.ecg) chartLog.addToFile(data16);

  data16.forEach((element) {
    // remove the first data point on the left
    chartData.removeAt(0);

    // each x decrese by 1 to shift the chart left
    chartData.forEach((element2) {
      element2.x--;
    });
    // add one time at the end of the right side
    chartData.add(ChartData(chartData.length, element));
  });
}
