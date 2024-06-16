import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/logIn.dart';
import 'package:intl/intl.dart';
import '../userInterface/findActivity.dart';
import '../main.dart';
import '../userInterface/myReservations.dart';
import 'myActivities.dart';

class AddActivity extends StatefulWidget {
  const AddActivity({Key? key}) : super(key: key);

  @override
  _AddActivityState createState() => _AddActivityState();
}

class _AddActivityState extends State<AddActivity> {
  @override
  void initState() {
    super.initState();
    checkIfUserIsAdmin();
  }
  // form variables
  final _formKey = GlobalKey<FormState>();
  final TextEditingController activityNameController = TextEditingController();
  final TextEditingController activityDescriptionController = TextEditingController();
  final TextEditingController activityStreetController = TextEditingController();
  final TextEditingController activityHouseController = TextEditingController();
  final TextEditingController activityCityController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController timeStartController = TextEditingController();
  final TextEditingController timeEndController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController numberOfPlacesController = TextEditingController();
  var db = FirebaseFirestore.instance;

  // sport activities variables
  String currentUserEmail = '';
  bool? isCurrentUserAdmin;
  String activityName = '';
  String activityDescription = '';
  String street = '';
  String house = '';
  String city = '';
  String pickedActivityDate = '';
  String activityPickedTimeStart = '';
  String activityPickedTimeEnd = '';
  double price = 0;
  int numberOfPlaces = 0;
  String currentAdminEmail = '';
  String activityId = '';

  void getFormData(){
    activityName = activityNameController.text.toString();
    activityDescription = activityDescriptionController.text.toString();
    street = activityStreetController.text.toString();
    house = activityHouseController.text.toString();
    city = activityCityController.text.toString();
    price = double.parse(priceController.text);
    numberOfPlaces = int.parse(numberOfPlacesController.text);
    activityId = activityName + DateTime.now().toString() + street + house;
  }

  Future<void> checkIfUserIsAdmin() async {
    await getUser();
    // check IfUserIsAdmin by email
    if(await ifCurrentUserIsAdmin() == false){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoInScreen()),
      );
    }
  }

  Future<void> getUser() async {
    FirebaseAuth.instance
        .authStateChanges()
        .listen((User? user) {
      if (user != null) {
        currentUserEmail = user.email!;
      }else{
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoInScreen()),
        );
      }
    });
  }

  Future<bool> ifCurrentUserIsAdmin() async => db.collection("users").where("email", isEqualTo: currentUserEmail).get().then(
          (querySnapshot) {
        for (var docSnapshot in querySnapshot.docs) {
          return docSnapshot['isAdmin'];
        }
        return false;
      },
      onError: (e) => print("Error completing: $e"),
    );

  // get admin email
  Future<void> getUserEmail() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        currentAdminEmail = user.email!;
      }
    });
  }

  // add activity to database
  Future<void> addActivityToDB() async {
    final activity = <String, dynamic>{
    "currentAdminEmail": currentAdminEmail,
    "activityId": activityId,
    "activityName": activityName,
    "activityDescription": activityDescription,
    "street": street,
    "house": house,
    "city": city,
    "pickedActivityDate": pickedActivityDate,
    "activityPickedTimeStart": activityPickedTimeStart,
    "activityPickedTimeEnd": activityPickedTimeEnd,
    "price": price,
    "numberOfPlaces": numberOfPlaces,
    };
    db.collection("physicalActivities").add(activity);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create an activity'),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (String result) async{
              switch (result) {
                case 'My activities':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyActivities()),
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
                // other options
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'My activities',
                child: Text('My activities'),
              ),
              const PopupMenuItem<String>(
                value: 'My reservations',
                child: Text('My reservations'),
              ),
              const PopupMenuItem<String>(
                value: 'Choose activity',
                child: Text('Choose activity'),
              ),
              const PopupMenuItem<String>(
                value: 'Log out',
                child: Text('Log out'),
              ),
              // Można dodać więcej opcji tutaj
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, top: 12, right: 24),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: activityNameController,
                    decoration: const InputDecoration(
                      labelText: 'Activity name',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'please enter data';
                      } else if (value.length > 25) {
                        return 'name must be < then 25 characters';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: activityDescriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Activity description',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      } else if (value.length > 255) {
                        return 'description must be < then 255 characters';
                      }
                      return null;
                    },
                  ),
                  // address widgets
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: TextFormField(
                          controller: activityStreetController,
                          decoration: const InputDecoration(
                            labelText: 'street',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter data';
                            } else if (value.length > 30) {
                              return 'Street must be less than 30 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        flex: 2,
                        // Ustawiamy mniejszy flex factor dla pola "House number"
                        child: TextFormField(
                          controller: activityHouseController,
                          decoration: const InputDecoration(
                            labelText: 'house',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter data';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        // Ustawiamy większy flex factor dla pola "City"
                        child: TextFormField(
                          controller: activityCityController,
                          decoration: const InputDecoration(
                            labelText: 'city',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter data';
                            } else if (value.length > 30) {
                              return 'City must be less than 30 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  // date time fields
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: dateController,
                          decoration: const InputDecoration(
                            labelText: 'date',
                          ),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        flex: 3,
                        child: TextFormField(
                          controller: timeStartController,
                          decoration: const InputDecoration(
                            labelText: 'time start',
                          ),
                          enabled: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: timeEndController,
                          decoration: const InputDecoration(
                            labelText: 'time end',
                          ),
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  // date time widgets
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          // Ustawiam większy flex factor dla pola "Street"
                          child: ElevatedButton(
                            onPressed: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please, choose date')),
                                );
                              } else {
                                dateController.text = DateFormat('dd-MM-yyyy')
                                    .format(pickedDate)
                                    .toString();
                                pickedActivityDate = DateFormat('dd-MM-yyyy')
                                    .format(pickedDate)
                                    .toString();
                              }
                            },
                            child: const Text('Date'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          flex: 3,
                          // Ustawiamy mniejszy flex factor dla pola "House number"
                          child: ElevatedButton(
                            onPressed: () async {
                              TimeOfDay? pickedTimeStart = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTimeStart == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please, choose start time')),
                                );
                              } else {
                                timeStartController.text =
                                    pickedTimeStart.format(context).toString();
                                activityPickedTimeStart =
                                    pickedTimeStart.format(context).toString();
                              }
                            },
                            child: const Text('Time start'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          // Ustawiamy większy flex factor dla pola "City"
                          child: ElevatedButton(
                            onPressed: () async {
                              TimeOfDay? pickedTimeEnd = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (pickedTimeEnd == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Please, choose end time')),
                                );
                              } else {
                                timeEndController.text =
                                    pickedTimeEnd.format(context).toString();
                                activityPickedTimeEnd =
                                    pickedTimeEnd.format(context).toString();
                              }
                            },
                            child: const Text('Time end'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // price and numerous of places
                  Row(
                    children: [
                      Flexible(
                        flex: 1,
                        // Ustawiamy mniejszy flex factor dla pola "House number"
                        child: TextFormField(
                          controller: priceController,
                          decoration: const InputDecoration(
                            labelText: 'price in USD',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter price';
                            } else if (num.tryParse(value) == null) {
                              return 'wrong value';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 80),
                      Expanded(
                        flex: 1,
                        // Ustawiamy większy flex factor dla pola "City"
                        child: TextFormField(
                          controller: numberOfPlacesController,
                          decoration: const InputDecoration(
                            labelText: 'places',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter data';
                            } else if (num.tryParse(value) == null) {
                              return 'wrong value';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  // Create an activity widget
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate() &&
                            pickedActivityDate != '' &&
                            activityPickedTimeStart != '' &&
                            activityPickedTimeEnd != ''){
                          getFormData();

                          // get user email
                          await getUserEmail();
                          // send data to firebase
                          if (currentAdminEmail != '') {
                            await addActivityToDB();
                            // setState(() {
                            //   activityNameController.text = '';
                            //   activityDescriptionController.text = '';
                            // });
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddActivity(),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Activity was added')),
                            );
                          }else{
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                  Text('Session finished, log in please')),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LoInScreen(),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Please, enter data, date and time')),
                          );
                        }
                      },
                      child: const Text('Create an activity'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
