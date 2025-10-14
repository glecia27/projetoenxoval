import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text('Mudou o titulo', ), backgroundColor: Colors.black87,),
        backgroundColor: Colors.grey[800],
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          //filhos
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(color: Colors.transparent),
                child: Text('Minha Home Page', style: TextStyle(fontSize: 50)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
