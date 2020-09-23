import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SplashScreenByLuke extends StatefulWidget {
  @override
  _SplashScreenByLukeState createState() => _SplashScreenByLukeState();
}

class _SplashScreenByLukeState extends State<SplashScreenByLuke> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.pink),
              ),
              SizedBox(
                height: 24.0,
              ),
              Text(
                'Loading ...',
                style: TextStyle(
                  color: Colors.grey[200],
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
          ),
        ),
      )
    );
  }
}
