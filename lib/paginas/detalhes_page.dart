import 'package:flutter/material.dart';

import '../db_service/db_service_models.dart';

class DetalhesPage extends StatefulWidget {
  // ⭐ 1. Adicionar o Produto como parâmetro obrigatório
  final Product product;

  const DetalhesPage({super.key, required this.product});

  @override
  State<DetalhesPage> createState() => _DetalhesPageState();
}

class _DetalhesPageState extends State<DetalhesPage> {
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
              'Preço: R\$ ${widget.product.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // adiconar ao carrinho
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: Text("Acidionar ao Carinho"),
            ),
          ],
        ),
      ),
    );
  }
}
