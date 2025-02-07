import 'package:ecomind/models/user.dart';
import 'package:ecomind/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // create user obj based on FireBaseUser
  UserObj? _userFormFirebaseUser(User user) {
    return user != null ? UserObj(uid: user.uid) : null;
  }

  //auth change user stream
  Stream<UserObj?> get user {
    return _auth.authStateChanges().map((User? user) {
      if (user == null) return null; // Ensure we return null safely
      return _userFormFirebaseUser(user);
    });
  }


  // sign in anon
  // Future signInAnon() async {
  //   try {
  //     UserCredential result = await _auth.signInAnonymously();
  //     User? user = result.user;
  //     return _userFormFirebaseUser(user!);
  //   }
  //   catch(e) {
  //     print(e.toString());
  //     return null;
  //   }
  // }

  // sign in with email & password
  Future SignInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFormFirebaseUser(user!);
    }
    catch(e) {
      print(e.toString());
      return null;
    }
  }

  // register with email & password
  Future registerWithEmailAndPassword(String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      // create a new document for the user with the uid
      await DatabaseService(uid: user!.uid).updateUserData(username, 0, {'hi':'hello'}, [{'name':'product1','price':'300rs'},{'name':'product2','price':'500rs'}]);
      return _userFormFirebaseUser(user);
    }
    catch(e) {
      print(e.toString());
      return null;
    }
  }

  //sign out
  Future signOut() async {
    try{
      return await _auth.signOut();
    }
    catch(e) {
      print(e.toString());
      return null;
    }
  }

}