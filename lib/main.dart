import 'package:flutter/material.dart';
import 'package:chatbot/chatbot_page.dart';

void main() {
  runApp(EcoMindApp());
}

class EcoMindApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoMind Chatbot',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("EcoMind", style:TextStyle(color: Colors.white) ), backgroundColor: Colors.blue,centerTitle: true,),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to EcoMind Chatbot!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatBotPage()),
                );
              },
              child: Text("Start Chat", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
