import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Patient Monitor',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: Colors.cyan.shade300,
          secondary: Colors.purpleAccent.shade100,
          tertiary: Colors.greenAccent.shade400,
          background: const Color(0xFF0A0A1A),
          surface: const Color(0xFF12121F),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF181832),
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
      ),
      home: const MyHomePage(title: 'Patient Monitoring Dashboard'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  double distance = 0.0;
  double acceleration = 0.0;
  double bpm = 0.0;
  double stat = 0.0;
  double tiltAngle = 0.0;
  String fallStatus = "No Fall Detected";
  bool isLoading = true;
  bool notified = false;
  late AnimationController _animationController;

  // Last update timestamp
  String lastUpdated = "Loading...";

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  void _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/flutter');

    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    final status = await Permission.notification.status;
    print("Notification permission status: $status");
  }

  Future<void> _showLocalNotification(String title, String body) async {
    try {
      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'fall_detection_channel',
        'Fall Detection Alerts',
        channelDescription: 'Alerts when a fall is detected',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        fullScreenIntent: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

      print("Showing notification: $title - $body");
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformDetails,
        payload: 'fall_detected',
      );

      print("Notification sent successfully");
    } catch (e) {
      print("Error showing notification: $e");
    }
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.thingspeak.com/channels/2727321/feeds.json?api_key=VISS2VG966XREE7A&results=2'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final feeds = data['feeds'] as List;
        if (feeds.isNotEmpty) {
          final latestFeed = feeds.last;

          String previousFallStatus = fallStatus;
          double previousStat = stat;

          setState(() {
            // Extracting values from the response
            distance = double.tryParse(latestFeed['field3'] ?? '0') ?? 0.0;
            acceleration = double.tryParse(latestFeed['field1'] ?? '0') ?? 0.0;
            bpm = double.tryParse(latestFeed['field2'] ?? '0') ?? 0.0;
            stat = double.tryParse(latestFeed['field4'] ?? '0') ?? 0.0;
            tiltAngle = double.tryParse(latestFeed['field5'] ?? '0') ?? 0.0;

            // Update timestamp
            lastUpdated = DateTime.now().toString().substring(0, 19);

            // Updating fall status based on the 'stat' value
            fallStatus = (stat >= 1.0) ? "Fall Detected!" : "No Fall Detected";

            isLoading = false;
          });

          // Extra debugging for fall detection
          print("Stat value: $stat, Previous: $previousStat");
          print("Fall status: $fallStatus, Previous: $previousFallStatus");

          // Only send notification if fall status changed from "No Fall" to "Fall Detected"
          if (fallStatus == "Fall Detected!" && previousFallStatus != "Fall Detected!" && !notified) {
            print("FALL DETECTED! stat value: $stat - Sending notification now...");
            notified = true; // Prevent multiple notifications

            if (!_animationController.isAnimating) {
              _animationController.repeat(reverse: true);
            }

            // Send only one notification when fall is detected
            _showLocalNotification("FALL DETECTED!", "Person may need immediate assistance");
          } else if (fallStatus != "Fall Detected!") {
            notified = false; // Reset notification flag when fall is no longer detected
            if (_animationController.isAnimating) {
              _animationController.stop();
              _animationController.reset();
            }
          }
        }
      } else {
        setState(() {
          isLoading = false;
          fallStatus = 'Error fetching data';
        });
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
        fallStatus = 'Error: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _initializeNotifications(); // Initialize notifications once

    fetchData(); // Initial fetch
    Timer.periodic(const Duration(seconds: 8), (timer) {
      fetchData(); // Refresh data every 8 seconds
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? _buildLoadingScreen()
          : _buildMainContent(),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A1A),
            const Color(0xFF151530),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.health_and_safety_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Patient Monitoring',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading patient data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 180,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade800,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A1A),
            const Color(0xFF151530),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            // Status banner at the top
            _buildStatusBanner(),
            // Main content area
            Expanded(
              child: _buildVitalsDisplay(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Patient ID: #3892',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.settings_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: fallStatus == "Fall Detected!"
                  ? Color.lerp(
                Colors.red.shade900,
                Colors.red.shade800,
                _animationController.value,
              )
                  : Color(0xFF114433),
              boxShadow: [
                BoxShadow(
                  color: fallStatus == "Fall Detected!"
                      ? Colors.red.withOpacity(0.5)
                      : Colors.green.withOpacity(0.3),
                  blurRadius: fallStatus == "Fall Detected!" ? 15 : 10,
                  spreadRadius: fallStatus == "Fall Detected!" ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    fallStatus == "Fall Detected!"
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fallStatus,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Last updated: $lastUpdated',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (fallStatus == "Fall Detected!")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'ALERT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVitalsDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'Vital Signs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Main grid of vitals
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildVitalGridCard(
                  icon: Icons.favorite,
                  title: 'Heart Rate',
                  value: '${bpm.toStringAsFixed(1)}',
                  unit: 'BPM',
                  color: Colors.redAccent.shade200,
                  highValue: bpm > 100,
                  lowValue: bpm < 60,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GraphPage(graphType: 'Heart Rate'),
                      ),
                    );
                  },
                ),
                _buildVitalGridCard(
                  icon: Icons.speed,
                  title: 'Acceleration',
                  value: '${acceleration.toStringAsFixed(2)}',
                  unit: 'g',
                  color: Colors.amberAccent.shade200,
                  highValue: acceleration > 1.5,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GraphPage(graphType: 'Acceleration'),
                      ),
                    );
                  },
                ),
                _buildVitalGridCard(
                  icon: Icons.straighten,
                  title: 'Distance',
                  value: '${distance.toStringAsFixed(1)}',
                  unit: 'cm',
                  color: Colors.cyanAccent.shade200,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GraphPage(graphType: 'Distance'),
                      ),
                    );
                  },
                ),
                _buildVitalGridCard(
                  icon: Icons.rotate_90_degrees_ccw,
                  title: 'Tilt Angle',
                  value: '${tiltAngle.toStringAsFixed(1)}',
                  unit: '°',
                  color: Colors.purpleAccent.shade100,
                  highValue: tiltAngle > 45,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GraphPage(graphType: 'Tilt Angle'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Fall status specific card
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: _buildFallRiskCard(),
          ),

          // Actions row
          Row(
            children: [
              Expanded(
                child: _buildGlassButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh',
                  onPressed: fetchData,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildGlassButton(
                  icon: Icons.notifications_active_rounded,
                  label: 'Test Alert',
                  onPressed: () {
                    _showLocalNotification("Test Alert", "This is a test notification");
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalGridCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required Color color,
    bool highValue = false,
    bool lowValue = false,
    void Function()? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1A1A2E),
              const Color(0xFF16162C),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background gradient and patterns
              Positioned(
                top: -15,
                right: -15,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -20,
                left: -20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.05),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        if (highValue || lowValue)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (highValue ? Colors.redAccent : Colors.blueAccent)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              highValue ? 'HIGH' : 'LOW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: highValue ? Colors.redAccent : Colors.blueAccent,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade300,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            unit,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Touch effect overlay
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  splashColor: color.withOpacity(0.1),
                  highlightColor: color.withOpacity(0.05),
                  child: Container(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallRiskCard() {
    Color cardColor = stat >= 1.0 ? Colors.redAccent.shade200 : Colors.greenAccent.shade400;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E),
            stat >= 1.0 ? const Color(0xFF2A1A1A) : const Color(0xFF1A2A1A),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: cardColor.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GraphPage(graphType: 'Fall Status'),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          splashColor: cardColor.withOpacity(0.1),
          highlightColor: cardColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    stat >= 1.0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: cardColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat >= 1.0 ? 'Fall Risk: High' : 'Fall Risk: Low',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fall status value: ${stat.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class GraphPage extends StatefulWidget {
  final String graphType;

  const GraphPage({Key? key, this.graphType = 'Acceleration'}) : super(key: key);

  @override
  _GraphPageState createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  List<FlSpot> graphData = [];
  bool isLoading = true;
  String errorMessage = '';

  // Fetch graph data from ThingSpeak API
  Future<void> fetchGraphData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://api.thingspeak.com/channels/2727321/feeds.json?api_key=VISS2VG966XREE7A&results=25'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<FlSpot> tempData = [];

        // Use index as x-axis value instead of timestamp
        int index = 0;
        for (var feed in data['feeds']) {
          double value = 0.0;

          if (widget.graphType == 'Acceleration') {
            value = double.tryParse(feed['field1'] ?? '0') ?? 0.0;
          } else if (widget.graphType == 'Heart Rate') {
            value = double.tryParse(feed['field2'] ?? '0') ?? 0.0;
          } else if (widget.graphType == 'Distance') {
            value = double.tryParse(feed['field3'] ?? '0') ?? 0.0;
          } else if (widget.graphType == 'Fall Status') {
            value = double.tryParse(feed['field4'] ?? '0') ?? 0.0;
          } else if (widget.graphType == 'Tilt Angle') {
            value = double.tryParse(feed['field5'] ?? '0') ?? 0.0;
          }

          tempData.add(FlSpot(index.toDouble(), value));
          index++;
        }

        setState(() {
          graphData = tempData;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGraphData();
  }

  Color _getGraphColor() {
    switch (widget.graphType) {
    case 'Acceleration':
    return Colors.amberAccent.shade200;
    case 'Heart Rate':
    return Colors.redAccent.shade200;
    case 'Distance':
      return Colors.cyanAccent.shade200;
      case 'Fall Status':
        return Colors.redAccent.shade400;
      case 'Tilt Angle':
        return Colors.purpleAccent.shade100;
      default:
        return Colors.greenAccent.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.graphType} Trend',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xFF0A0A1A).withOpacity(0.8),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchGraphData,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A1A),
              const Color(0xFF151530),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: _getGraphColor(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading ${widget.graphType} data...',
                    style: TextStyle(
                      color: Colors.grey.shade300,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : errorMessage.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.redAccent,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: fetchGraphData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueAccent.shade700,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
                : _buildGraph(),
          ),
        ),
      ),
    );
  }

  Widget _buildGraph() {
    Color graphColor = _getGraphColor();
    String unit = '';

    switch (widget.graphType) {
      case 'Acceleration':
        unit = 'g';
        break;
      case 'Heart Rate':
        unit = 'BPM';
        break;
      case 'Distance':
        unit = 'cm';
        break;
      case 'Fall Status':
        unit = '';
        break;
      case 'Tilt Angle':
        unit = '°';
        break;
    }

    double minY = 0;
    double maxY = 0;

    if (graphData.isNotEmpty) {
      minY = graphData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxY = graphData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

      // Add some padding to the min/max
      double padding = (maxY - minY) * 0.1;
      minY = minY - padding;
      maxY = maxY + padding;

      // Ensure minY is at least 0 for certain metrics
      if (['Heart Rate', 'Distance', 'Fall Status'].contains(widget.graphType)) {
        minY = minY < 0 ? 0 : minY;
      }
    }

    return Column(
      children: [
        // Header card with stats
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E),
                const Color(0xFF16162C),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: graphColor.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: graphColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForGraphType(),
                          color: graphColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${widget.graphType} Overview',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Last 25 Readings',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    label: 'Current',
                    value: graphData.isNotEmpty
                        ? '${graphData.last.y.toStringAsFixed(1)}$unit'
                        : '0$unit',
                    color: graphColor,
                  ),
                  _buildStatItem(
                    label: 'Average',
                    value: graphData.isNotEmpty
                        ? '${(graphData.map((spot) => spot.y).reduce((a, b) => a + b) / graphData.length).toStringAsFixed(1)}$unit'
                        : '0$unit',
                    color: graphColor,
                  ),
                  _buildStatItem(
                    label: 'Maximum',
                    value: graphData.isNotEmpty
                        ? '${maxY.toStringAsFixed(1)}$unit'
                        : '0$unit',
                    color: graphColor,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Main graph card
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16162C),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: graphData.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Colors.grey.shade600,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data available',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.white.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 4,
                      getTitles: (value) {
                        if (value % 4 != 0) {
                          return '';
                        }
                        return value.toInt().toString();
                      },
                      getTextStyles: (context, value) => TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      margin: 8,
                    ),
                    leftTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY - minY) / 5,
                      getTitles: (value) {
                        return value.toStringAsFixed(1);
                      },
                      getTextStyles: (context, value) => TextStyle(
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      reservedSize: 42,
                    ),
                    rightTitles: SideTitles(showTitles: false),
                    topTitles: SideTitles(showTitles: false),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  minX: 0,
                  maxX: graphData.length - 1.0,
                  minY: minY,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: const Color(0xFF2A2A3E),
                      tooltipRoundedRadius: 16,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          return LineTooltipItem(
                            '${touchedSpot.y.toStringAsFixed(2)}$unit',
                            TextStyle(
                              color: graphColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                    handleBuiltInTouches: true,
                    getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: Colors.white.withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                          FlDotData(
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 6,
                                color: graphColor,
                                strokeWidth: 2,
                                strokeColor: Colors.white,
                              );
                            },
                          ),
                        );
                      }).toList();
                    },
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: graphData,
                      isCurved: true,
                      colors: [
                        graphColor.withOpacity(0.5),
                        graphColor,
                      ],
                      colorStops: [0.0, 1.0],
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        colors: [
                          graphColor.withOpacity(0.3),
                          graphColor.withOpacity(0.0),
                        ],
                        gradientColorStops: [0.0, 1.0],
                        gradientFrom: const Offset(0, 0),
                        gradientTo: const Offset(0, 1),
                      ),
                    ),
                  ],
                )
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForGraphType() {
    switch (widget.graphType) {
      case 'Acceleration':
        return Icons.speed;
      case 'Heart Rate':
        return Icons.favorite;
      case 'Distance':
        return Icons.straighten;
      case 'Fall Status':
        return Icons.warning_amber_rounded;
      case 'Tilt Angle':
        return Icons.rotate_90_degrees_ccw;
      default:
        return Icons.show_chart;
    }
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}