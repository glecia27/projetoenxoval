import 'package:flutter/material.dart';
import 'package:projetoenxoval/paginas/carrinho_page.dart';
import 'package:projetoenxoval/paginas/favoritos_page.dart';
import 'package:projetoenxoval/paginas/tela_loguin.dart';

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

  void _mostrarOpcoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha uma opção',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.pop(context); // fecha
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Esta função não esta ativa no momento'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configurações'),
                onTap: () {
                  Navigator.pop(context); // fecha
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Esta função não esta ativa no momento'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Sair'),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const TelaLoguin()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

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
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 0.0,
          unselectedFontSize: 0.0,
          //backgroundColor: Colors.transparent,
          iconSize: 35,
          elevation: 150,

          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ''),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: ''),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '',
            ), // botão do meio
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.pinkAccent,
          onTap: (index) {
            if (index == 3) {
              _mostrarOpcoes(context); // abre o modal
            } else {
              _onItemTapped(index);
            }
          },
        ),
      ),
    );
  }
}
