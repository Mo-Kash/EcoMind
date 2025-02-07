import 'package:ecomind/services/auth.dart';
import 'package:ecomind/shared/constants.dart';
import 'package:ecomind/shared/loading.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  const SignIn({super.key, required this.toggleView});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {

  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  String email = '';
  String password = '';
  String error = '';
  double fsize = 25.0;
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return loading ? Loading() : Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20.0,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.recycling_outlined,
                  size: 40.0,
                ),
                SizedBox(
                  width: 10.0,
                ),
                Text(
                  'EcoMind',
                  style: TextStyle(
                      fontSize: 40.0,
                      fontWeight: FontWeight.bold
                  ),
                )
              ],
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            'Good to see you back!',
                            style: TextStyle(
                                fontSize: fsize-8,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.0,),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          hintText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey), // Optional: Email icon
                          fillColor: Colors.grey[200], // Light grey background
                          filled: true, // Ensures background color is applied
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0), // Rounded border
                            borderSide: BorderSide(color: Colors.grey, width: 1), // Grey border
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide: BorderSide(color: Colors.black, width: 1.5), // Black border when focused
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (val) => val == null || val.isEmpty ? 'Enter an email' : null,
                        onChanged: (val) {
                          setState(() {
                            email = val;
                          });
                        },
                      ),
                      SizedBox(height: 20.0,),
                      TextFormField(
                        decoration: textInputDecoration.copyWith(
                          hintText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey), // Lock icon for better UX
                          fillColor: Colors.grey[200], // Light grey background
                          filled: true, // Apply background color
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0), // Rounded border
                            borderSide: BorderSide(color: Colors.grey, width: 1), // Grey border
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4.0),
                            borderSide: BorderSide(color: Colors.black, width: 1.5), // Black border when focused
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure ? Icons.visibility_off : Icons.visibility, // Change icon based on visibility
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure; // Toggle visibility
                              });
                            },
                          ),
                        ),
                        obscureText: _isObscure, // Toggle password visibility
                        validator: (val) => val!.length < 6 ? 'Enter a password more than 6 characters' : null,
                        onChanged: (val) {
                          setState(() {
                            password = val;
                          });
                        },
                      ),
                      SizedBox(height: 20.0,),
                      SizedBox(
                        width: double.infinity, // Set button width
                        child: TextButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(Colors.green[600]),
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), // Add border radius
                              ),
                            ),
                          ),
                          onPressed: () async{
                            if(_formKey.currentState!.validate()) {
                              setState(() {
                                loading = true;
                              });
                              dynamic result = await _auth.SignInWithEmailAndPassword(email, password);
                              if(result == null) {
                                setState(() {
                                  error = 'could not sign in with those credentials';
                                  loading = false;
                                });
                              }
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              'Continue',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: fsize,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.0,),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0), // Cleaner padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Center align items
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(color: Colors.black87, fontSize: 16.0), // Styling for normal text
                                children: [
                                  TextSpan(text: "Don't have an account? "), // Normal text
                                  WidgetSpan(
                                    child: TextButton(
                                      onPressed: () {
                                        widget.toggleView();
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero, // Remove button padding
                                        minimumSize: Size(0, 0), // Remove extra spacing
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Shrink tap area
                                      ),
                                      child: Text(
                                        'Sign Up',
                                        style: TextStyle(color: Colors.blue[900], fontSize: 16.0, fontWeight: FontWeight.bold), // Styled text
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        error,
                        style: TextStyle(color: Colors.red, fontSize: 14.0),
                      )
                    ],
                  )
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}