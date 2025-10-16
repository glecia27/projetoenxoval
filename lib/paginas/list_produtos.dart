import 'package:flutter/material.dart';

class ListProdutos extends StatelessWidget {
  const ListProdutos({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Center(child: Text('Lista de Produtos'))],
    );
  }
}
