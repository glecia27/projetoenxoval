import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db_service/db_service_models.dart';

class ListProdutos extends StatefulWidget {
  const ListProdutos({super.key});

  @override
  State<ListProdutos> createState() => _ListProdutosState();
}

class _ListProdutosState extends State<ListProdutos> {
  late Future<List<Product>> _productsFuture;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Inicializa o Future chamando o método do banco de dados
    _productsFuture = DatabaseService().getProducts();
  }

  // Função para recarregar a lista (útil após adicionar/deletar um produto)
  void _refreshProducts() {
    setState(() {
      _productsFuture = _dbService.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Container controla as cores de fundo
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE494E5), Color(0xFFE09FE5), Color(0xFFFFFFE5)],
          stops: [0.2, 0.3, 0.9],
        ),
      ),

      // 2. Usando FutureBuilder para lidar com a busca assíncrona
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          // 4. Estado de Erro
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar produtos: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          // 5. Estado Sem Dados (Lista Vazia)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Nenhum porduto cadastrado',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          } // 6. Estado de Sucesso (Dados Prontos!)
          final products = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _refreshProducts();
            },
            child: ListView.builder(
              itemCount: products.length,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              itemBuilder: (context, index) {
                final product = products[index];
                final priceFormatter = NumberFormat.currency(
                  locale: 'pt_BR',
                  symbol: 'R\$',
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Card(
                    // Estilo do Card
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    // Conteúdo do Card
                    child: InkWell(
                      borderRadius: BorderRadius.circular(15),
                      onTap: () {
                        // Lógica para ir para a tela de detalhes do produto
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Detalhes de ${product.name}'),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Imagem do Produto
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(15),
                            ),
                            child: product.imageUrl.startsWith('http')
                                ? Image.network(
                                    product.imageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        color: Colors.grey[200],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            color: Colors.pinkAccent,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 50,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ),
                                  )
                                : Image.asset(
                                    product.imageUrl,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 200,
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 50,
                                                  color: Colors.black45,
                                                ),
                                              ),
                                            ),
                                  ),
                          ),

                          // 2. Informações (Nome e Preço)
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  priceFormatter.format(product.price),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary, // Cor principal
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
