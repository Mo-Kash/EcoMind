import 'package:ecomind/services/buyer_page.dart';
import 'package:ecomind/services/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/brew.dart';
import '../models/user.dart';
import '../screens/home/brew_list.dart';
import '../screens/home/home.dart';
import 'database.dart';

class SellerPage extends StatefulWidget {
  const SellerPage({super.key});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {

  int _selectedIndex = 2;

  bool profile_page = false;
  bool home_page = false;
  bool buyer_page = false;

  void _onHomeTapped() {
    print('Home tapped');
    home_page = true;
    // You can add navigation or other actions here
  }

  void _onBuyerTapped() {
    print('Search tapped');
    buyer_page = true;
    // You can add search actions here
  }

  void _onSellerTapped() {
    print('Notifications tapped');
    // Add logic for notifications here
  }


  void _onProfileTapped() {
    print('Profile tapped');
    profile_page = true;
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserObj?>(context);
    return profile_page ? ProfilePage() : home_page ? Home() : buyer_page ? BuyerPage() : StreamProvider<List<Brew>?>.value(
      initialData: null,
      value: DatabaseService(uid: user!.uid).brews,
      child: Scaffold(
        body: Container(
          child: BrewList(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              // counter += 1;
            });
          },
          backgroundColor: Colors.blue[800],
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
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