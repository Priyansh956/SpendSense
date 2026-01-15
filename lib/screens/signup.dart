import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _signupName = TextEditingController();
  final TextEditingController _passwordPin = TextEditingController();
  final TextEditingController _confirmPin = TextEditingController();

  Future<void> signupUser() async{
    try{
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _signupName.text.trim(),
        password: _passwordPin.text.trim(),
      );

      // SAVE PROFILE DATA RATHER THAN PASSWORD
      await FirebaseFirestore.instance.collection("users").doc(userCredential.user!.uid).set({
        "email" : _signupName.text.trim(),
        "password" : _passwordPin.text.trim(),
      });

      if(!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account successfully registered!"),
          )
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
    on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Signup failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    void dispose(){
      _signupName.dispose();
      _passwordPin.dispose();
    }

    return Scaffold(
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsetsGeometry.all(16),
              child: Column(
                children: [
                  Container(
                    width: 400,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: AssetImage('images/signupImage.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  SizedBox(height: 8),

                  TextFormField(
                      controller: _signupName,
                      decoration: InputDecoration(
                        label: Row(
                          children: [
                            Icon(Icons.person),
                            SizedBox(width: 8),
                            Text("Email ID"),
                          ],
                        ),
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return 'Please enter a valid email';
                        }
                        return null;
                      }
                  ),

                  SizedBox(height: 16 ),

                  TextFormField(
                      controller: _passwordPin,
                      decoration: InputDecoration(
                        label: Row(
                          children: [
                            Icon(Icons.lock),
                            SizedBox(width: 8),
                            Text("Password"),
                          ],
                        ),
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return 'Please enter a valid Password';
                        }
                        return null;
                      }
                  ),

                  SizedBox(height: 16 ),

                  TextFormField(
                      controller: _confirmPin,
                      decoration: InputDecoration(
                        label: Row(
                          children: [
                            Icon(Icons.lock_person),
                            SizedBox(width: 8),
                            Text("Confirm Password"),
                          ],
                        ),
                      ),
                      validator: (value){
                        if(value == null || value.isEmpty){
                          return 'Please enter a valid Password';
                        }
                        else if(_passwordPin.text != _confirmPin.text){
                          return 'The passwords do not match!';
                        }
                      }
                  ),

                  SizedBox(height: 48),

                  Row(
                    children: <Widget>[
                      Expanded(
                        child: ElevatedButton(
                            onPressed: (){
                              if(_formKey.currentState!.validate()){
                                signupUser();
                              }
                            },
                            child: Text(
                              "Sign Up",
                            )
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8,),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      const SizedBox(width: 4),
                      CupertinoButton(
                        padding: EdgeInsets.zero, // IMPORTANT
                        child: const Text("Log in"),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }
}
