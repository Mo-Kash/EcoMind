import 'package:ecomind/models/user.dart';
import 'package:ecomind/services/database.dart';
import 'package:ecomind/shared/loading.dart';
import 'package:flutter/material.dart';
import 'package:ecomind/shared/constants.dart';
import 'package:provider/provider.dart';

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {

  final _formKey = GlobalKey<FormState>();

  // form values
  String _currentName = '';
  int _currentRewardPoints = 100;
  Map _currentUserInfo = {};
  List _currentProductDetails = [];

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<UserObj?>(context);

    return StreamBuilder<UserData>(
      stream: DatabaseService(uid: user!.uid).userData,
      builder: (context,snapshot) {
        if(snapshot.hasData) {
          UserData? userData = snapshot.data;
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  'Username',
                  style: TextStyle(fontSize: 18.0),
                ),
                SizedBox(height: 20.0,),
                TextFormField(
                  initialValue: _currentName.isEmpty ? userData!.name : _currentName,
                  decoration: textInputDecoration,
                  validator: (val) => val!.isEmpty ? 'Please enter a name' : null,
                  onChanged: (val) => setState(() {
                    _currentName = val;
                  }),
                ),
                SizedBox(height: 20.0,),
                // DropdownButtonFormField(
                //   value: _currentSugars.isEmpty ? userData!.sugars : _currentSugars,
                //   decoration: textInputDecoration,
                //   items: sugars.map((sugar) {
                //     return DropdownMenuItem(
                //       value: sugar,
                //       child: Text('$sugar sugars'),
                //     );
                //   }).toList(),
                //   onChanged: (val) {
                //     setState(() {
                //       _currentSugars = val!;
                //     });
                //   },
                // ),
                // Slider(
                //   min: 100,
                //   max: 900,
                //   divisions: 8,
                //   value: (_currentName.isEmpty) ? _currentStrength.toDouble() : userData!.strength.toDouble(),
                //   // label: _currentStrength.round().toString(),
                //   activeColor: Colors.brown[_currentStrength],
                //   inactiveColor: Colors.brown[_currentStrength],
                //   onChanged: (val) {
                //     setState(() {
                //       _currentStrength = val.toInt();
                //     });
                //   },
                // ),
                ElevatedButton(
                  child: Text(
                    'Update',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async{
                    if(_formKey.currentState!.validate()) {
                      await DatabaseService(uid: user.uid).updateUserData(
                        _currentName.isEmpty ? userData!.name : _currentName,
                        (_currentRewardPoints != null) ? _currentRewardPoints : userData!.rewardpoints,
                        (_currentUserInfo != null) ? _currentUserInfo : userData!.userinfo,
                        (_currentProductDetails != null) ? _currentProductDetails : userData!.productdetails,
                      );
                      Navigator.pop(context);
                    }
                  },
                )
              ],
            )
          );
        }
        else {
          return Loading();
        }
      }
    );
  }
}
