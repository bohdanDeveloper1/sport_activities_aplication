import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../userInterface/findActivity.dart';
import '../userInterface/myReservations.dart';
import 'addActivity.dart';

class MyActivities extends StatefulWidget {
  const MyActivities({Key? key}) : super(key: key);

  @override
  _MyActivitiesState createState() => _MyActivitiesState();
}

class _MyActivitiesState extends State<MyActivities> {
  var db = FirebaseFirestore.instance;
  User? currentUser;
  List<QueryDocumentSnapshot>? activities;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    initializeActivities();
  }

  Future<void> initializeActivities() async {
    await getMyActivitiesData();
  }

  Future<void> getMyActivitiesData() async {
    if (currentUser == null) {
      print("No user logged in.");
      return;
    }

    try {
      QuerySnapshot querySnapshot = await db.collection("physicalActivities")
          .where("currentAdminEmail", isEqualTo: currentUser!.email!)
          .get();
      setState(() {
        activities = querySnapshot.docs;
      });
    } catch (e) {
      print("Error retrieving activities: $e");
    }
  }

  Future<void> getCurrentUser() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        if (user != null) {
          setState(() {
            currentUser = user;
            initializeActivities(); // виклик після отримання користувача
          });
        }
      });
    } else {
      await initializeActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('My activities'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) async {
              switch (result) {
                case 'Create an activity':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddActivity()),
                  );
                  break;
                case 'Choose activity':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FindActivity()),
                  );
                  break;
                case 'My reservations':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyReservations()),
                  );
                  break;
                case 'Log out':
                  await FirebaseAuth.instance.signOut();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SportActivitiesApp()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'Create an activity',
                child: Text('Create an activity'),
              ),
              const PopupMenuItem<String>(
                value: 'Choose activity',
                child: Text('Choose activity'),
              ),
              const PopupMenuItem<String>(
                value: 'My reservations',
                child: Text('My reservations'),
              ),
              const PopupMenuItem<String>(
                value: 'Log out',
                child: Text('Log out'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 15, right: 15, top: 20,),
          child: Column(
            children: [
              if (activities != null && activities!.isNotEmpty)
                Column(
                  children: activities!.map((activity) {
                    var activityData = activity.data() as Map<String, dynamic>;
                    var userCount = (activityData['users'] != null && activityData['users'] is List)
                        ? activityData['users'].length
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ListTile(
                              title: Text(activityData['activityName'], style: const TextStyle(fontSize: 20)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(activityData['city'] + ', ' + activityData['street'] + ', ' + activityData['house'], style: const TextStyle(fontSize: 18)),
                                  Text('${'from: ' + activityData['activityPickedTimeStart']} to: ' + activityData['activityPickedTimeEnd'], style: const TextStyle(fontSize: 18)),
                                  Text('Places: ${activityData['numberOfPlaces']}', style: const TextStyle(fontSize: 18)),
                                  Text('Price: ${activityData['price']} USD', style: const TextStyle(fontSize: 18)),
                                  Text('Number of users: $userCount', style: const TextStyle(fontSize: 18)),
                                  Text('Your income: ${userCount * activityData['price']} USD', style: const TextStyle(fontSize: 18)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (activities == null || activities!.isEmpty)
                const Center(child: Text('You haven`t activities yet.', style: TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }
}

