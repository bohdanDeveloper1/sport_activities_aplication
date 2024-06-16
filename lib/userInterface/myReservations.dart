import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class MyReservations extends StatefulWidget {
  const MyReservations({Key? key}) : super(key: key);

  @override
  _MyReservationsState createState() => _MyReservationsState();
}

class _MyReservationsState extends State<MyReservations> {
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
    await getReservedActivitiesData();
  }

  Future<void> getReservedActivitiesData() async {
    if (currentUser == null) {
      print("No user logged in.");
      return;
    }

    try {
      QuerySnapshot querySnapshot = await db.collection("physicalActivities").where("users", arrayContains: currentUser!.email!).get();
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
          });
        }
      });
    }
  }

  Future<bool> deleteActivityFromReservations(String activityId) async {
    if (currentUser == null) {
      print("No user logged in.");
      return false;
    }

    try {
      String email = currentUser!.email!;
      QuerySnapshot userQuery = await db.collection("users").where("email", isEqualTo: email).get();

      if (userQuery.docs.isEmpty) {
        print("User with email $email not found.");
        return false;
      }

      DocumentReference userDoc = userQuery.docs.first.reference;
      DocumentReference activityDoc = db.collection("physicalActivities").doc(activityId);

      // Start a batch write
      WriteBatch batch = db.batch();

      // remove the activity from the user document
      batch.update(userDoc, {
        "activities": FieldValue.arrayRemove([activityId]),
      });

      // remove current user email from activity document
      // Increment the number of places in the activity
      batch.update(activityDoc, {
        "users": FieldValue.arrayRemove([email]),
        "numberOfPlaces": FieldValue.increment(1)
      });

      // Commit the batch
      await batch.commit();
      // Refresh reserved activities
      await getReservedActivitiesData();
      return true;
    } catch (e) {
      print("Error during add activity to current user: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Choose an activity'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) async {
              switch (result) {
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
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  child: const Text('Delete'),
                                  onPressed: () async {
                                    //  усунути активність користувачу,
                                    //   додати 1 місце до Places для активності
                                    //  todo: видалити email користувача з активності.
                                    // todo: показати сповіщення, що активність видалено
                                    String message = 'Work';
                                    if(await deleteActivityFromReservations(activity.id)){
                                      message = 'Activity was deleted';
                                    }else{
                                      message = 'Problem with deleting';
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                          Text(message)),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (activities == null || activities!.isEmpty)
                const Center(child: Text('You have`t reservations yet', style: TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }
}
