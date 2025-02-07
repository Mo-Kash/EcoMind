import 'package:ecomind/services/seller_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ecomind/screens/home/home.dart';
import 'package:ecomind/services/auth.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../screens/home/settings_form.dart';
import 'buyer_page.dart';
import 'database.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _auth = AuthService();
  double fsize = 25.0;
  int _selectedIndex = 3;

  bool seller_page = false;
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
    seller_page = true;
    // Add logic for notifications here
  }


  void _onProfileTapped() {
    print('Profile tapped');
  }

  @override
  Widget build(BuildContext context) {
    void _showSettingsPanel() {
      showModalBottomSheet(
          context: context,
          builder: (context) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 60.0),
              child: SettingsForm(),
            );
          }
      );
    }
    final user = Provider.of<UserObj?>(context);
    DatabaseService databaseService = DatabaseService(uid: user!.uid);

    return seller_page ? SellerPage() : home_page ? Home() : buyer_page ? BuyerPage() : Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
        // actions: [
        //   TextButton.icon(
        //     icon: Icon(
        //       Icons.person,
        //       color: Colors.black,
        //     ),
        //     label: Text(
        //       'logout',
        //       style: TextStyle(color: Colors.black),
        //     ),
        //     onPressed: () async {
        //       await _auth.signOut();
        //     },
        //   ),
        // ],
      ),
      body: StreamBuilder<UserData>(
        stream: databaseService.userData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No user data available'));
          }

          // If the data is successfully fetched, display it
          UserData userData = snapshot.data!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30.0, 20.0, 30.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.blue,  // Border color
                        width: 1.6,  // Border width
                      ),
                      borderRadius: BorderRadius.circular(10),  // Optional: add rounded corners
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(13.0),
                          child: Row(
                            children: [
                              SizedBox(width: 10.0),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: fsize + 4,
                                  backgroundImage: AssetImage('assets/profile_pic.png'),
                                ),
                              ),
                              SizedBox(width: 20.0),
                              Text(
                                userData.name ?? 'Guest User',
                                style: TextStyle(fontSize: fsize - 5),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: TextButton(
                            // icon: Icon(Icons.edit, color: Colors.blue, size: 20.0),
                            child: Text(
                              'Edit >',
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                            onPressed: () {
                              // Implement your edit button action here
                              print('Edit button pressed');
                              _showSettingsPanel();
                              // For example, navigate to an edit screen:
                              // Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage()));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.0,),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),  // Optional: add rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          SizedBox(width: 10.0),
                          Icon(
                            Icons.wallet_outlined,
                            size: fsize,
                          ),
                          SizedBox(width: 20.0),
                          Text(
                            'My wallet',
                            style: TextStyle(fontSize: fsize-3, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),  // Optional: add rounded corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          SizedBox(width: 10.0),
                          Icon(
                            CupertinoIcons.info,
                            size: fsize,
                          ),
                          SizedBox(width: 20.0),
                          Text(
                            'Support',
                            style: TextStyle(fontSize: fsize-3, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.0,),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),  // Optional: add rounded corners
                    ),
                    child: TextButton.icon(
                      onPressed: () async {
                        await _auth.signOut();
                      },
                      label: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            SizedBox(width: 10.0),
                            Icon(
                              Icons.logout_outlined,
                              size: fsize,
                              color: Colors.black,
                            ),
                            SizedBox(width: 20.0),
                            Text(
                              'Logout',
                              style: TextStyle(fontSize: fsize-3, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
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
    );
  }
}
