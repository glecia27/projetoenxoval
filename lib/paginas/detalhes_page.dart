import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Import para formatar o preço

import '../db_service/db_service_models.dart';

class DetalhesPage extends StatefulWidget {
  // ⭐ 1. Adicionar o Produto como parâmetro obrigatório
  final Product product;
  // ⭐ 2. Adicionar o Usuário como parâmetro obrigatório
  final User user;

  const DetalhesPage({super.key, required this.product, required this.user});

  @override
  State<DetalhesPage> createState() => _DetalhesPageState();
}

class _DetalhesPageState extends State<DetalhesPage> {
  final DatabaseService _dbService = DatabaseService();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
  );

  // ⭐ NOVA FUNÇÃO: Adicionar o produto ao carrinho
  void _addToCart() async {
    final product = widget.product;
    final userId = widget.user.id;
    const quantity = 1; // Adiciona 1 unidade por padrão

    try {
      await _dbService.addToShoppingList(
        userId,
        product.name,
        product.price,
        quantity,
        product.imageUrl,

      );

      // Feedback para o usuário
      // [SnackBar removido a pedido]

    } catch (e) {
      // Feedback de erro
      // [SnackBar removido a pedido]

      print('Erro ao adicionar ao carrinho: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Detalhes do Produto',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.product.imageUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey[300],
                  child: const Center(child: Text('Imagem não carregada')),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // exibição do preço
            Text(
              'Preço: ${_currencyFormatter.format(widget.product.price)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // ⭐ BOTÃO: Adicionar ao carrinho (Agora clicável)
            InkWell(
              onTap: _addToCart, // Chama a função que adiciona ao BD
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 200,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.pink[400], // Cor mais forte para ser um botão
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Adicionar ao carrinho',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

