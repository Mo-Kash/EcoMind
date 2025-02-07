import 'package:ecomind/screens/home/home.dart';
import 'package:ecomind/services/profile_page.dart';
import 'package:ecomind/services/seller_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/brew.dart';
import '../models/user.dart';
import '../screens/home/brew_list.dart';
import 'database.dart';

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key});

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {

  int _selectedIndex = 1;

  bool profile_page = false;
  bool home_page = false;
  bool seller_page = false;

  void _onHomeTapped() {
    print('Home tapped');
    home_page = true;
    // You can add navigation or other actions here
  }

  void _onBuyerTapped() {
    print('Search tapped');
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
    return profile_page ? ProfilePage() : home_page ? Home() : seller_page ? SellerPage() : StreamProvider<List<Brew>?>.value(
      initialData: null,
      value: DatabaseService(uid: user!.uid).brews,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: Column(
              children: [
                Text(
                  'EcoMart',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
                Expanded(
                  child: BrewList()
                ),
              ],
            ),
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
