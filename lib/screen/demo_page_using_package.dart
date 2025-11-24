import 'package:flutter/material.dart';
import 'package:custom_refresh_indicator/custom_refresh_indicator.dart';
// ---------------------------------------------------------------------------
// 2. DEMO IMPLEMENTATION
// ---------------------------------------------------------------------------

class DemoPageForPackage extends StatefulWidget {
  const DemoPageForPackage({super.key});

  @override
  State<DemoPageForPackage> createState() => _DemoPageForPackageState();
}

class _DemoPageForPackageState extends State<DemoPageForPackage> {
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
      body: CustomMaterialIndicator(
        onRefresh: _loadMoreData,
        indicatorBuilder: (context, controller) {
          return CircularProgressIndicator();
        },
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