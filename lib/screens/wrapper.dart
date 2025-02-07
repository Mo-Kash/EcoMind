import 'package:ecomind/screens/authenticate/authenticate.dart';
import 'package:ecomind/screens/home/home.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {

    final user = Provider.of<UserObj?>(context);

    //return wither Home or Authenticate Widget

    if(user == null){
      return Authenticate();
    }
    else {
      return Home();
    }

  }
}
