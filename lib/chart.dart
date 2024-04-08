import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math';

// https://pub.dev/packages/slide_switcher

 extension Precision on double {
    double toPrecision(int fractionDigits) {
        double mod = pow(10, fractionDigits).toDouble();
        return ((this * mod).round().toDouble() / mod);
    }
}

class LineChartWidget extends StatelessWidget {
    final List<GraphPoint> points;
    final double maxY;
    final double minY;
    final List<String> timeS;

    const LineChartWidget(
        this.points,
        this.maxY,
        this.minY,
        this.timeS,
        {super.key});


    @override
    Widget build(BuildContext context) {
        final bottomTitles = getBottomTitles(timeS, 2);
        return AspectRatio(
            aspectRatio: 1.5,
            child: LineChart(
                LineChartData(
                    titlesData: FlTitlesData(
                        //show: false,
                        topTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: bottomTitles),
                    ),
                    clipData: const FlClipData.all(),
                    maxY: maxY.ceil().toDouble(),
                    minY: minY.floor().toDouble(),


                    lineBarsData: [
                        LineChartBarData(
                            spots: points.map((point) => FlSpot(point.x.toPrecision(3), point.y.toPrecision(3))).toList(),
                            isCurved: true,
                            dotData: const FlDotData(
                                show: false,
                            ),
                        ),
                    ],

                    ),
                    ),
                    );
    }
}


class GraphPoint {
    final double x;
    final double y;

    GraphPoint({required this.x, required this.y});
}


SideTitles getBottomTitles (List<String> timeS, int step){
    final out = SideTitles(
        reservedSize : 40,
        showTitles: true,
        getTitlesWidget: (value, meta) {
            final dateString = timeS;
            String text = '';
            if ((value.toInt() + 1) % step == 0) {
                text = dateString[value.toInt()];
            }
            if (text.isNotEmpty) {
                return SingleChildScrollView(child: Column(
                    children: [
                        Text(text),
                    ]
                ));
            } else {
                return Container();
            }
        },
        );
    return out;
}
