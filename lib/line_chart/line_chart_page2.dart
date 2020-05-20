import 'package:flutter/material.dart';

import 'samples/line_chart_sample4.dart';
import 'samples/line_chart_sample7.dart';

class LineChartPage2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView(
            children: <Widget>[
              const Text(
                'LineChart',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              LineChartSample4(),
              LineChartSample7(),
            ],
          ),
        ),
      ),
    );
  }
}
