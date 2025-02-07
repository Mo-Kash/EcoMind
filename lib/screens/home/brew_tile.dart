import 'package:flutter/material.dart';
import 'package:ecomind/models/brew.dart';

class BrewTile extends StatelessWidget {
  final Brew brew;
  const BrewTile({super.key, required this.brew});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.0),
      child: Card(
        margin: EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 0.0),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: CircleAvatar(
              radius: 25.0,
              // backgroundColor: Colors.brown[brew.strength],
              backgroundImage: AssetImage(
                'assets/profile_pic.png',
              ),
            ),
            title: Text(
              brew.name,
            ),
            // subtitle: Text('Take ${brew.sugars} sugars(s)'),
          ),
        ),
      ),
    );
  }
}
