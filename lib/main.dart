import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// authentification
import 'auth/auth.dart';
import 'auth/logIn.dart';
import 'adminInterface/addActivity.dart';
import 'userInterface/findActivity.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(SportActivitiesApp());
}

class SportActivitiesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport activities application',
      home: AuthCheck(),
      routes: {
        '/auth': (context) => const CreateAnAccount(),
      },
    );
  }
}

class AuthCheck extends StatelessWidget {
  final db = FirebaseFirestore.instance;

  Future<bool> checkIfUserIsAdmin(String userEmail) async {
    final querySnapshot = await db.collection("users").where("email", isEqualTo: userEmail).get();
    for (var docSnapshot in querySnapshot.docs) {
      bool ifUserIsAdmin = docSnapshot.get('isAdmin');
      return ifUserIsAdmin;
    }
    return false; // false, jeśli nie znaleziono użytkownika z podanym adresem e-mail
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        // if waiting data, show CircularProgressIndicator
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          User? user = snapshot.data;
          if (user != null) {
            return FutureBuilder<bool>(
              future: checkIfUserIsAdmin(user.email!),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (adminSnapshot.hasData) {
                  bool isAdmin = adminSnapshot.data!;
                  return isAdmin ? const AddActivity() : const FindActivity();
                } else {
                  return const Center(child: Text('Error checking admin status'));
                }
              },
            );
          } else {
            return LoInScreen();
          }
        } else {
          return LoInScreen();
        }
      },
    );
  }
}

