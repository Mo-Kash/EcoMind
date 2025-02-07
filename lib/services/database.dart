import 'package:ecomind/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecomind/models/brew.dart';

class DatabaseService {

  final String uid;
  DatabaseService({required this.uid});

  // collection reference
  final CollectionReference brewCollection = FirebaseFirestore.instance.collection('brews');

  Future updateUserData(String name, int rewardpoints, Map userinfo , List productdetails) async{
    return await brewCollection.doc(uid).set({
      'name': name,
      'rewardpoints': rewardpoints,
      'userinfo': userinfo,
      'productdetails': productdetails,
    });
  }

  // brew list from snapshot
  List<Brew> _brewListFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc){
      var data = doc.data() as Map<String, dynamic>;
      return Brew(
        name: data['name'] ?? '',
        rewardpoints: data['rewardpoints'] ?? 0,
        userinfo: data['userinfo'] ?? {'hi': 'hello'},
        productdetails: data['productdetails'] ?? [{'name':'details1'}],
      );
    }).toList();
  }

  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    var snapShot = snapshot.data() as Map<String, dynamic>;
    return UserData(
      uid: uid,
      rewardpoints: snapShot['rewardpoints'],
      name: snapShot['name'],
      userinfo: snapShot['userinfo'],
      productdetails: snapShot['productdetails'],
    );
  }

  Stream<List<Brew>> get brews {
    return brewCollection.snapshots().map(_brewListFromSnapshot);
  }

  // get user doc stream
  Stream<UserData> get userData {
    return brewCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }

}