class UserObj {
  final String uid;
  UserObj({required this.uid});
}

class UserData {
  final String uid;
  final String name;
  final int rewardpoints;
  final Map userinfo;
  final List productdetails;
  UserData({required this.uid, required this.rewardpoints, required this.name, required this.userinfo, required this.productdetails});
}