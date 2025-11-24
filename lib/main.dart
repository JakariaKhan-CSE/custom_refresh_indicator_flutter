import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Refresh Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DemoPage(),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. THE REUSABLE WIDGET
// ---------------------------------------------------------------------------

class LogoRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Widget logo;
  final double refreshTriggerPullDistance;
  final double indicatorSize;

  const LogoRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    required this.logo,
    this.refreshTriggerPullDistance = 100.0,
    this.indicatorSize = 60.0,
  });

  @override
  State<LogoRefreshIndicator> createState() => _LogoRefreshIndicatorState();
}

class _LogoRefreshIndicatorState extends State<LogoRefreshIndicator> {
  // State to track if we are currently loading data
  bool _isRefreshing = false;

  // State to track how far the user has pulled
  double _pullDistance = 0.0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // LAYER 1: The Background Loader (Image + Spinner)
        // This sits behind the list and becomes visible when the list moves down
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          // We limit the height to the pull distance so it stays at the top
          height: widget.refreshTriggerPullDistance,
          child: Center(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              // Fade in the indicator as we pull
              opacity: (_pullDistance > 20 || _isRefreshing) ? 1.0 : 0.0,
              child: SizedBox(
                height: widget.indicatorSize,
                width: widget.indicatorSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // The Inner Image
                    SizedBox(
                      width: widget.indicatorSize * 0.6,
                      height: widget.indicatorSize * 0.6,
                      child: widget.logo,
                    ),
                    // The Outer Progress Indicator
                    CircularProgressIndicator(
                      // If refreshing, indeterminate (spinning).
                      // If pulling, determinate (fills up based on pull).
                      value: _isRefreshing
                          ? null
                          : math.min(_pullDistance / widget.refreshTriggerPullDistance, 1.0),
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // LAYER 2: The Actual Scrollable List
        // We use a NotificationListener to detect scroll events
        NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: AnimatedPadding(
            // This is the magic: We add top padding to the list to "hold" it
            // open while refreshing, pushing the content down to reveal the loader.
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              top: _isRefreshing ? widget.refreshTriggerPullDistance : 0,
            ),
            child: widget.child,
          ),
        ),
      ],
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    // 1. Handle scroll updates (while dragging)
    if (notification is ScrollUpdateNotification) {
      // We only care if we are at the top of the list (extentBefore == 0)
      if (notification.metrics.extentBefore == 0) {
        // If pixels are negative, it means we are overscrolling at the top
        if (notification.metrics.pixels < 0) {
          setState(() {
            // Convert negative pixels (overscroll) to positive pull distance
            _pullDistance = notification.metrics.pixels.abs();
          });
        } else if (_pullDistance > 0) {
          setState(() {
            _pullDistance = 0.0;
          });
        }
      }
    }

    // 2. Handle scroll end (user released the drag)
    if (notification is ScrollEndNotification) {
      if (!_isRefreshing && _pullDistance >= widget.refreshTriggerPullDistance) {
        _startRefresh();
      } else {
        setState(() {
          _pullDistance = 0.0;
        });
      }
    }

    return false; // Allow event to bubble up
  }

  Future<void> _startRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Haptic feedback (optional)
    // HapticFeedback.mediumImpact();

    try {
      // Call the user's refresh function
      await widget.onRefresh();
    } finally {
      // When done, wait a tiny bit for smoothness, then close
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _pullDistance = 0.0;
        });
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 2. DEMO IMPLEMENTATION
// ---------------------------------------------------------------------------

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  // Sample data source
  List<String> items = List.generate(10, (index) => "Item ${10 - index}");

  // Simulate an API call to get more data
  Future<void> _loadMoreData() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 3));

    // Add new data to the top of the list
    final nextId = items.length + 1;
    final newItems = [
      "New Data $nextId (Fresh!)",
      "New Data ${nextId + 1} (Fresh!)",
    ];

    setState(() {
      // Prepend new items (Show more data logic)
      items.insertAll(0, newItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Custom Refresher"),
        backgroundColor: Colors.blueAccent.shade100,
      ),
      backgroundColor: Colors.grey[100],
      body: LogoRefreshIndicator(
        onRefresh: _loadMoreData,
        // The custom image inside the spinner
        logo: const Icon(Icons.flutter_dash, color: Colors.blue, size: 30),
        // Alternatively, use an image:
        // logo: Image.asset('assets/logo.png'),

        // The List
        child: ListView.builder(
          // IMPORTANT: physics must allow overscroll bouncing for this to work
          // 'BouncingScrollPhysics' ensures iOS-style bounce on Android too,
          // which is required for the pull-down visualization.
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text('${items.length - index}'),
                ),
                title: Text(
                  items[index],
                  style: TextStyle(
                    fontWeight: items[index].contains("Fresh")
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: items[index].contains("Fresh")
                        ? Colors.green
                        : Colors.black,
                  ),
                ),
                subtitle: const Text("Pull down to see the custom spinner"),
              ),
            );
          },
        ),
      ),
    );
  }
}