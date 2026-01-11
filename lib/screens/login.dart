import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:spendsense/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendsense/screens/homepage.dart';
import 'package:spendsense/theme/app_color_schema.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(LoginPage());
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> loginUser() async{
    try{
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
      );

      if(mounted){
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Homepage(),
            ),
        );
      }

      _emailController.clear();
      _passwordController.clear();
    }

    catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    //TODO: REMOVE MATERIAL APP WIDGET AFTER TESTING IS DONE
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Login Page"),
          // backgroundColor: Color.fromRGBO(13, 13, 13, 1),
        ),
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

                    //TODO: ADD FORGOT PASSWORD
                    // SizedBox(height: 96,),

                    SizedBox(height: 48),

                    Row(
                      children: <Widget>[
                          Expanded(
                          child: ElevatedButton(
                              onPressed: (){
                                if(_formKey.currentState!.validate()){
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Login Successful!"),
                                    )
                                  );
                                }
                              },
                              child: Text(
                                "Submit",
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
      ),
    );
  }
}

