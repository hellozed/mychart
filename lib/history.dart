import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

import 'file.dart';
import 'main.dart';
import 'home.dart';

//FIXME: 
//log ppg, temperature with time.

/* ----------------------------------------------------------------------------
 * display chart from the history file in the disk
 * 
 * use stream to read the file, because log file might be too big. 
 * ----------------------------------------------------------------------------*/


List<ChartData> historyChartData = [];

//----------------------------------
// history page
//----------------------------------
class HistoryChart extends StatefulWidget {
  @override
  _HistoryChartState createState() => _HistoryChartState();
}

class _HistoryChartState extends State<HistoryChart> {
  int historyChartSize = 100;
  int chartForwardOffset = 0;
  double screenXmax, screenYmax;

  @override
  void dispose() {
    //reset
    historyChartSize = 100;
    chartForwardOffset = 0;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenXmax = MediaQuery.of(context).size.width;
    screenYmax = MediaQuery.of(context).size.height;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: new Icon(Icons.arrow_back),
        onPressed: () {
          navigatorToHomePage();
        },
      ),
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
                      myChartBlock(),
                    ]),
              ),
            ]),
      ),
    );
  }

  //----------------------------------
  // build chart stream
  //----------------------------------
  StreamBuilder<List<int>> myChartBuilder() {
    // load chart data
    chartLog.readFile(historyChartSize, chartForwardOffset);  //FIXME: the first graphic is empty

    List<charts.Series<ChartData, num>> series1 = [];

    return StreamBuilder(
        stream: chartLog.readStream,
        initialData: [],
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // do not move this line to the top
          series1 = [
            charts.Series<ChartData, int>(
              id: 'ChartData',
              //dash line style
              //dashPatternFn: (_, __) => [8, 3, 2, 3],
              //dashPatternFn: (_, __) => [2, 2],
              colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
              measureFn: (ChartData sales, _) => sales.y,
              domainFn: (ChartData sales, _) => sales.x,
              data: historyChartData,
            ),
          ];

          if (snapshot.data != null) {
            List<int> ix = [];
            ix = snapshot.data;
            //print("stream: $ix");
            if (ix.length > 0) {
              int i = 0;
              historyChartData.clear();
              ix.forEach((element) {
                historyChartData.add(ChartData(i++, element));
              });
            }
          }
          return Padding(
            padding: EdgeInsets.all(2.0),
            child: charts.LineChart(series1, animate: false, behaviors: [
              charts.PanAndZoomBehavior(),
            ] //turn on the pan znd zoom feature
                ),
          );
        });
  }

  //----------------------------------
  // block for display chart
  //----------------------------------
  Expanded myChartBlock() {
    return Expanded(
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
                child: myChartBuilder(),
              ),

              //text
              Positioned(
                top: 30.0,
                left: 30.0,
                child: Text(
                  "ECG History",
                  style: Theme.of(context).textTheme.headline5,
                ),
              ),
            ],
          ),
        ),
        onTapDown: (details) {
          var xPercent = details.globalPosition.dx / screenXmax; // 0%~ 100%
          var yPercent = details.globalPosition.dy / screenYmax;

          //print("pan: $xPercent $yPercent");

          // on the x axis
          if ((yPercent > 0.30) && (yPercent < 0.7)) {
            if (xPercent < 0.3)
              chartForwardOffset += 30; //each time shift left
            else if (xPercent > 0.7) {
              chartForwardOffset -= 30; //each time shift left
              if (chartForwardOffset < 0) chartForwardOffset = 0;
            }
          }

          // on the y axis
          if ((xPercent > 0.30) && (xPercent < 0.7)) {
            if (yPercent < 0.5)
              historyChartSize += 30; //each time shift left
            else if (yPercent > 0.7) {
              historyChartSize -= 30; //each time shift left
              if (historyChartSize < 40) historyChartSize = 40;
            }
          }

          chartLog.readFile(historyChartSize, chartForwardOffset);
          setState(() {});
        },
      ),
    );
  }
}
