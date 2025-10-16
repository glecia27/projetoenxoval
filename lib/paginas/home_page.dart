import 'package:flutter/material.dart';
import 'package:projetoenxoval/paginas/carrinho_page.dart';
import 'package:projetoenxoval/paginas/favoritos_page.dart';

import 'list_produtos.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ListProdutos(),
    FavoritosPage(),
    CarrinhoPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedFontSize: 0.0,
          unselectedFontSize: 0.0,
          //backgroundColor: Colors.transparent,
          iconSize: 35,
          elevation: 150,

          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.black87,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
