import 'package:flutter/material.dart';
import 'package:projetoenxoval/paginas/carrinho_page.dart';
import 'package:projetoenxoval/paginas/favoritos_page.dart';
import 'package:projetoenxoval/paginas/tela_loguin.dart';

import '../db_service/db_service_models.dart';
import 'adicionar_produto.dart';
import 'list_produtos.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ListProdutosState> _listProdutosKey =
      GlobalKey<ListProdutosState>();
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      ListProdutos(
        key: _listProdutosKey,
        user: widget.user, // Passa),
      ),
      FavoriteProductsList(user: widget.user),
      CarrinhoPage(user: widget.user),
    ];
  }

  //Função para mostrar o modal e lidar com a atualização
  void _showAddProdutoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return AdicionarProduto(
          onProductAdded: () {
            print(
              "Produto Salvo! Agora, é nescessário chamar o refresh da ListProdutos.",
            );
          },
        );
      },
    );
  }

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

        floatingActionButton:
            (widget.user.accessLevel == 'vendedor' ||
                widget.user.accessLevel == 'administrador')
            ? FloatingActionButton(
                onPressed: () => _showAddProdutoModal(context),
                backgroundColor: Colors.pinkAccent,
                child: const Icon(Icons.add),
              )
            : null,

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
