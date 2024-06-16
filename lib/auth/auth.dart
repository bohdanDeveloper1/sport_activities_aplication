import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_pw_validator/flutter_pw_validator.dart';
import '../adminInterface/addActivity.dart';
import '../userInterface/findActivity.dart';

class CreateAnAccount extends StatefulWidget {
  const CreateAnAccount({Key? key}) : super(key: key);

  @override
  _CreateAnAccountState createState() => _CreateAnAccountState();
}

class _CreateAnAccountState extends State<CreateAnAccount> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<FlutterPwValidatorState> validatorKey =
  GlobalKey<FlutterPwValidatorState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  var db = FirebaseFirestore.instance;

  String userEmail = '';
  String userPassword = '';
  bool isPasswordCorrect = false;
  String ifUserCreated = '';
  bool isAdmin = false;

  Future<void> createUserAccount(String userEmail, String userPassword) async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: userEmail,
        password: userPassword,
      );
      ifUserCreated = 'account created';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        ifUserCreated = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        ifUserCreated = 'The account already exists for that email.';
      }
    } catch (e) {
      ifUserCreated = 'undefined problem, try again';
    }
  }

  Future<void> addUserToDatabase(String userEmail) async {
    final user = <String, dynamic>{
      "email": userEmail,
      "isAdmin": isAdmin
    };

    db.collection("users").add(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Create an account'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 12,),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                  ),
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value!.isEmpty || !EmailValidator.validate(value)) {
                      return 'Please enter valid email';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value!.isEmpty || isPasswordCorrect != true) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                Row(
                  children: [
                    Checkbox(
                      checkColor: Colors.black,
                      value: isAdmin,
                      onChanged: (bool? value) {
                        setState(() {
                          isAdmin = value!;
                        });
                      },
                    ),
                    const Text('Account with opportunity to post activities')
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      userEmail = emailController.text.toString();
                      userPassword = passwordController.text.toString();

                      if (_formKey.currentState!.validate() && isPasswordCorrect == true) {
                        await createUserAccount(userEmail, userPassword);
                        await addUserToDatabase(userEmail);

                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                            builder: (context) => isAdmin ? const AddActivity() : const FindActivity(),
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ifUserCreated),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Wrong email or password"),
                          ),
                        );
                      }
                    },
                    child: const Text('Create an account'),
                  ),
                ),
                FlutterPwValidator(
                  key: validatorKey,
                  controller: passwordController,
                  minLength: 6,
                  uppercaseCharCount: 0,
                  lowercaseCharCount: 2,
                  numericCharCount: 2,
                  specialCharCount: 0,
                  normalCharCount: 0,
                  width: 400,
                  height: 200,
                  onSuccess: () {
                    isPasswordCorrect = true;
                  },
                  onFail: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


















