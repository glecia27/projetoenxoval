import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Certifique-se de que os caminhos para seus modelos e serviços estão corretos
import '../db_service/db_service_models.dart';
import 'detalhes_page.dart';

class FavoriteProductsList extends StatefulWidget {
  final User user;

  const FavoriteProductsList({super.key, required this.user});

  @override
  State<FavoriteProductsList> createState() => _FavoriteProductsListState();
}

class _FavoriteProductsListState extends State<FavoriteProductsList> {
  late Future<List<Product>> _favoriteProductsFuture;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Inicializa a busca dos produtos favoritos
    _loadFavorites();
  }

  // Função para recarregar a lista de favoritos
  void _loadFavorites() {
    setState(() {
      _favoriteProductsFuture = _dbService.getFavoriteProducts(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usando FutureBuilder para lidar com a busca assíncrona
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE494E5), Color(0xFFE09FE5), Color(0xFFFFFFE5)],
          stops: [0.2, 0.3, 0.9],
        ),
      ),
      child: FutureBuilder<List<Product>>(
        future: _favoriteProductsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Estado de Erro
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar favoritos: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final favoriteProducts = snapshot.data!;

          // Estado Sem Dados (Lista Vazia de Favoritos)
          if (favoriteProducts.isEmpty) {
            return const Center(
              child: Text(
                'Você ainda não adicionou nenhum produto aos favoritos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          // Estado de Sucesso (Exibe a lista)
          return RefreshIndicator(
            onRefresh: () async {
              _loadFavorites(); // Recarrega a lista ao puxar para baixo
            },
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Número de colunas
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                mainAxisExtent: 270.0, // Altura dos itens
              ),
              itemCount: favoriteProducts.length,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              itemBuilder: (context, index) {
                final product = favoriteProducts[index];
                final priceFormatter = NumberFormat.currency(
                  locale: 'pt_BR',
                  symbol: 'R\$',
                );

                // *** UI do Card (Quase a mesma que você já tem) ***
                return Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => DetalhesPage(product: product, user: widget.user,),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Imagem do Produto e Botão de Favorito (Sempre preenchido aqui)
                        Stack(
                          children: [
                            // 1. Imagem
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              // Lógica de imagem (simplificada para este exemplo)
                              child: Image.network(
                                product.imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.fill,
                                // Você pode adicionar seus builders de loading/error aqui
                              ),
                            ),

                            // 2. Botão de Favorito (Sempre preenchido, com função para remover)
                            if (product.id != null)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.favorite, // Ícone sempre preenchido
                                      color: Colors.redAccent,
                                      size: 24.0,
                                    ),
                                    onPressed: () async {
                                      // Remove dos favoritos e atualiza a lista
                                      await _dbService.removeProductFromFavorites(
                                          widget.user.id, product.id!);
                                      _loadFavorites();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                '${product.name} removido dos favoritos!')),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Informações (Nome e Preço)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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