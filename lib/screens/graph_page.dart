import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphPage extends StatelessWidget {
  final String graphType;

  const GraphPage({Key? key, required this.graphType}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data for demonstration purposes
    List<FlSpot> graphData = _getGraphData(graphType);

    return Scaffold(
      appBar: AppBar(
        title: Text('$graphType Graph'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(show: true),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  spots: graphData,
                  isCurved: true,
                  colors: [Colors.blue],
                  barWidth: 4,
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Generate graph data based on graphType
  List<FlSpot> _getGraphData(String graphType) {
    // Sample data for each graph type
    if (graphType == 'Distance') {
      return [
        FlSpot(0, 10), // (x, y) pairs for the graph
        FlSpot(1, 12),
        FlSpot(2, 8),
        FlSpot(3, 15),
      ];
    } else if (graphType == 'Acceleration') {
      return [
        FlSpot(0, 0.1),
        FlSpot(1, 0.3),
        FlSpot(2, 0.2),
        FlSpot(3, 0.4),
      ];
    } else if (graphType == 'Heart Rate') {
      return [
        FlSpot(0, 72),
        FlSpot(1, 75),
        FlSpot(2, 78),
        FlSpot(3, 80),
      ];
    } else if (graphType == 'Fall Status') {
      return [
        FlSpot(0, 0), // 0 for no fall, 1 for fall detected
        FlSpot(1, 1),
        FlSpot(2, 0),
        FlSpot(3, 1),
      ];
    } else {
      return []; // Return an empty list if no valid graphType is found
    }
  }
}
