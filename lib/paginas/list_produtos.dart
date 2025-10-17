import 'package:flutter/material.dart';

class ListProdutos extends StatefulWidget {
  const ListProdutos({super.key});

  @override
  State<ListProdutos> createState() => _ListProdutosState();
}

class _ListProdutosState extends State<ListProdutos> {
  @override
  Widget build(BuildContext context) {
    //Container controla as cores da pagina de lista de produtos
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE494E5), Color(0xFFE09FE5), Color(0xFFFFFFE5)],
          stops: [0.2, 0.3, 0.9],
        ),
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [Center(child: Text('Lista de Produtos'))],
      ),
    );
  }
}
