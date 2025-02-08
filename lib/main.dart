import 'package:flutter/material.dart';

void main() {
  runApp(WasteSortingGame());
}

class WasteSortingGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InfoScreen(),
    );
  }
}

class InfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
      appBar: AppBar(
        title: Text('Waste Sorting Game'),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Rules:',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Drag and drop waste items into the correct bin. Earn points for correct sorting!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WasteSortingScreen()),
                );
              },
              child: Text('Start Game', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class WasteSortingScreen extends StatefulWidget {
  @override
  _WasteSortingScreenState createState() => _WasteSortingScreenState();
}

class _WasteSortingScreenState extends State<WasteSortingScreen> {
  int score = 0;
  List<Map<String, String>> wasteItems = [];
  List<Map<String, String>> initialWasteItems = [
    {'name': 'Plastic Bottle', 'category': 'Recyclable'},
    {'name': 'Banana Peel', 'category': 'Organic'},
    {'name': 'Glass Bottle', 'category': 'Recyclable'},
    {'name': 'Paper', 'category': 'Recyclable'},
    {'name': 'Food Wrapper', 'category': 'Non-Recyclable'},
    {'name': 'Aluminum Can', 'category': 'Recyclable'},
    {'name': 'Cardboard Box', 'category': 'Recyclable'},
    {'name': 'Apple Core', 'category': 'Organic'},
    {'name': 'Broken Ceramic Plate', 'category': 'Non-Recyclable'},
    {'name': 'Milk Carton', 'category': 'Recyclable'},
    {'name': 'Used Tissue', 'category': 'Non-Recyclable'},
    {'name': 'Tea Bag', 'category': 'Organic'},
    {'name': 'Metal Fork', 'category': 'Recyclable'},
    {'name': 'Plastic Straw', 'category': 'Non-Recyclable'},
    {'name': 'Egg Shell', 'category': 'Organic'},
  ];

  List<String> bins = ['Recyclable', 'Organic', 'Non-Recyclable'];

  @override
  void initState() {
    super.initState();
    wasteItems = List.from(initialWasteItems);
  }

  void checkCorrectDrop(String item, String bin) {
    setState(() {
      int index = wasteItems.indexWhere((entry) => entry['name'] == item);
      if (index != -1) {
        if (wasteItems[index]['category'] == bin) {
          score += 10;
        } else {
          score -= 5;
        }
        wasteItems.removeAt(index);
      }
    });
  }

  void restartGame() {
    setState(() {
      score = 0;
      wasteItems = List.from(initialWasteItems);
    });
  }

  Widget _wasteItemCard(String name) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightGreen[100],
      appBar: AppBar(
        title: Text('Waste Sorting Game', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text('Score: $score', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800])),
          SizedBox(height: 20),
          Expanded(
            child: wasteItems.isNotEmpty
                ? Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(20),
                    itemCount: wasteItems.length,
                    itemBuilder: (context, index) {
                      var entry = wasteItems[index];
                      return Draggable<String>(
                        data: entry['name']!,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _wasteItemCard(entry['name']!),
                        ),
                        childWhenDragging: Container(),
                        child: _wasteItemCard(entry['name']!),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: bins.map((bin) {
                    return DragTarget<String>(
                      onWillAccept: (data) => true,
                      onAccept: (data) {
                        checkCorrectDrop(data, bin);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.28,
                          height: 140,
                          decoration: BoxDecoration(
                            color: candidateData.isNotEmpty ? Colors.green[400] : Colors.green[300],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green[800]!, width: 2),
                          ),
                          child: Center(
                            child: Text(bin, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
              ],
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Final Score: $score', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800])),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: restartGame,
                    child: Text('Play Again', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}