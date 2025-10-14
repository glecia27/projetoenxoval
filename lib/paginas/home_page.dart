import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('MEU TITULO', ), backgroundColor: Colors.green,),
        backgroundColor: Colors.grey[300],
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          //filhos
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(color: Colors.amberAccent),
                child: Text('HOMEPAGE', style: TextStyle(fontSize: 50)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
