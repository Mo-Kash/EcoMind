import 'package:ecomind/screens/home/brew_list.dart';
import 'package:ecomind/services/auth.dart';
import 'package:ecomind/services/buyer_page.dart';
import 'package:ecomind/services/seller_page.dart';
import 'package:flutter/material.dart';
import 'package:ecomind/services/database.dart';
import 'package:provider/provider.dart';

import '../../models/brew.dart';
import '../../models/user.dart';
import '../../services/profile_page.dart';

class Home extends StatefulWidget {
  Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthService _auth = AuthService();
  double fsize = 25.0;
  int _selectedIndex = 0;

  bool profile_page = false;
  bool buyer_page = false;
  bool seller_page = false;

  void _onHomeTapped() {
    print('Home tapped');
    // You can add navigation or other actions here
  }

  void _onBuyerTapped() {
    print('Search tapped');
    buyer_page = true;
    // You can add search actions here
  }

  void _onSellerTapped() {
    print('Notifications tapped');
    seller_page = true;
    // Add logic for notifications here
  }


  void _onProfileTapped() {
    print('Profile tapped');
    profile_page = true;
  }

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<UserObj?>(context);
    return profile_page ? ProfilePage() : buyer_page ? BuyerPage() : seller_page ? SellerPage() : StreamProvider<List<Brew>?>.value(
      initialData: null,
      value: DatabaseService(uid: user!.uid).brews,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Row(
            children: [
              SizedBox(width: 10.0),
              Icon(
                Icons.recycling_outlined,
                size: fsize + 10,
              ),
              SizedBox(width: 10.0),
              Text(
                'EcoMind',
                style: TextStyle(fontSize: fsize + 5, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0.0,
          actions: [
            TextButton.icon(
              icon: Icon(
                Icons.person,
                color: Colors.black,
              ),
              label: Text(
                'logout',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                await _auth.signOut();
              },
            ),
          ],
        ),
        body: Container(
          child: BrewList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          backgroundColor: Colors.white, // Optional: make the background white
          selectedItemColor: Colors.blue[900], // Set color for selected item
          unselectedItemColor: Colors.black,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            // Call the corresponding onTap function for each index
            if (index == 0) {
              _onHomeTapped();
            } else if (index == 1) {
              _onBuyerTapped();
            } else if (index == 2) {
              _onSellerTapped();
            } else if (index == 3) {
              _onProfileTapped();
            }
          },
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.money_outlined),
              label: 'Buyer',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.money_off),
              label: 'Seller',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
