import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendsense/screens/add_transaction_page_updated.dart';
import 'package:spendsense/screens/signup.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void loginCheck() async{
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(), password: _passwordController.text.trim(),
      );

      if(!mounted) return;

      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddTransactionPage()),
      );
    }
    on FirebaseAuthException catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message ?? "Login Failed"),
        )
      );
    }
  }
  
  @override
  void dispose(){
    _emailController.dispose();
    _passwordController.dispose();
  }

  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(title: Text("Login Page"),),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 400,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage('images/loginImage.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    SizedBox(height: 8),

                    TextFormField(
                      controller: _emailController,
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
                        controller: _passwordController,
                        obscureText: true,
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

                    CupertinoButton(
                        padding: EdgeInsets.zero,

                        child: Text("New user? Sign-Up"),
                        onPressed: (){
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => SignupPage()),
                          );
                        }
                    ),

                    SizedBox(height: 48),

                    Row(
                      children: <Widget>[
                          Expanded(
                          child: ElevatedButton(
                              onPressed: (){
                                if(_formKey.currentState!.validate()) {
                                  loginCheck();
                                }
                              },
                              child: Text(
                                "Login",
                              )
                          ),
                        ),
                      ],
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

