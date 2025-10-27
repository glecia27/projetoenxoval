import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db_service/db_service_models.dart'; // Certifique-se de que este caminho está correto
import 'detalhes_page.dart'; // Certifique-se de que este caminho está correto

class ListProdutos extends StatefulWidget {
  //A propriedade User para saber o nível de acesso
  final User user;

  const ListProdutos({
    required GlobalKey<ListProdutosState> key,
    required this.user,
  }) : super(key: key);

  @override
  State<ListProdutos> createState() => ListProdutosState();
}

class ListProdutosState extends State<ListProdutos> {
  late Future<List<Product>> _productsFuture;
  late Future<Set<int>> _favoriteIdsFuture;
  final DatabaseService _dbService = DatabaseService();

  // 1. Estado Local para Favoritos
  Set<int> _favoriteProductIds = {};

  @override
  void initState() {
    super.initState();
    // Inicializa o Future chamando o método do banco de dados
    _productsFuture = _dbService.getProducts();
    // Inicializa o Future dos IDs favoritos
    _favoriteIdsFuture = _loadFavorites();
  }

  // Função para carregar os IDs dos favoritos do usuário
  Future<Set<int>> _loadFavorites() async {
    final ids = await _dbService.getFavoriteProductIds(widget.user.id);
    // Armazena os IDs no estado local e retorna
    _favoriteProductIds = ids.toSet();
    return _favoriteProductIds;
  }

  // Função para alternar o estado de favorito
  Future<void> _toggleFavorite(int productId) async {
    final userId = widget.user.id;
    final isCurrentlyFavorite = _favoriteProductIds.contains(productId);

    // 1. Atualização do Estado Otimista (Rápida na UI)
    setState(() {
      if (isCurrentlyFavorite) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });

    // 2. Persistência no Banco de Dados
    try {
      if (isCurrentlyFavorite) {
        await _dbService.removeProductFromFavorites(userId, productId);
        // SnackBar de "removido" foi removida
      } else {
        await _dbService.addProductToFavorites(userId, productId);
        // SnackBar de "adicionado" foi removida
      }
    } catch (e) {
      // Em caso de erro, reverte o estado (Pessimista)
      setState(() {
        if (isCurrentlyFavorite) {
          _favoriteProductIds.add(productId); // Reverte a remoção
        } else {
          _favoriteProductIds.remove(productId); // Reverte a adição
        }
      });
      // SnackBar de "erro" foi removida
      print('Erro ao atualizar favoritos: $e'); // Mantém o log de erro no console
    }
  }

  // Método público para ser chamado pela GlobalKey da HomePage
  void refreshList() {
    _refreshProducts();
    _refreshFavorites();
  }

  // Função para recarregar a lista de produtos
  void _refreshProducts() {
    setState(() {
      _productsFuture = _dbService.getProducts();
    });
  }

  // Função para recarregar a lista de favoritos
  void _refreshFavorites() {
    setState(() {
      _favoriteIdsFuture = _loadFavorites();
    });
  }

  //Método para lidar com a exclusão de produtos ⭐
  Future<void> _deleteProduct(int productId) async {
    // 1. Mostrar Diálogo de Confirmação (Mantido como estava)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem certeza que deseja remover este produto do catálogo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    ) ??
        false;

    // 2. Se confirmado, execute a exclusão
    if (confirmed) {
      try {
        await _dbService.deleteProduct(productId);
        // SnackBar de "removido com sucesso" foi removida

        // Recarregar a lista após a exclusão
        _refreshProducts();
      } catch (e) {
        // SnackBar de "erro ao remover" foi removida
        print('Erro ao remover produto: $e'); // Adicionado para log
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Container controla as cores de fundo
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE494E5), Color(0xFFE09FE5), Color(0xFFFFFFE5)],
          stops: [0.2, 0.3, 0.9],
        ),
      ),

      // Combina os dois Futures (produtos e favoritos)
      child: FutureBuilder<List<dynamic>>(
        // Espera que ambos os Futures sejam concluídos
        future: Future.wait([_productsFuture, _favoriteIdsFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Estado de Erro (Verifica se algum dos futures falhou)
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar dados: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          // Estado de Sucesso (Dados Prontos!)
          final products = snapshot.data![0] as List<Product>;
          // Não precisamos do snapshot.data[1] pois _favoriteProductIds já foi atualizado em _loadFavorites

          // Estado Sem Dados (Lista Vazia)
          if (products.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum produto cadastrado',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          }

          // Verificação de Nível de Acesso
          final bool canDelete =
              widget.user.accessLevel == 'vendedor' ||
                  widget.user.accessLevel == 'administrador';

          return RefreshIndicator(
            onRefresh: () async {
              refreshList(); // Atualiza produtos E favoritos
            },
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Número de colunas
                crossAxisSpacing: 10.0, // Espaçamento entre as colunas
                mainAxisSpacing: 10.0, // Espaçamento entre as linhas
                mainAxisExtent: 270.0,
              ),
              itemCount: products.length,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              itemBuilder: (context, index) {
                final product = products[index];
                // Verifica se o produto está favoritado (com base no estado local)
                final isFavorite = product.id != null &&
                    _favoriteProductIds.contains(product.id);

                final priceFormatter = NumberFormat.currency(
                  locale: 'pt_BR',
                  symbol: 'R\$',
                );

                return Card(
                  //Estilo do Card
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  //Conteúdo do Card
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      //Lógica para ir para a tela de detalhes do produto
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => DetalhesPage(product: product, user: widget.user,),
                        ),
                      );

                      // SnackBar de "Detalhes de..." foi removida
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Imagem do Produto e Botão de Favorito
                        Stack(
                          children: [
                            // 1. Imagem do Produto
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(15),
                              ),
                              child: product.imageUrl.startsWith('http')
                                  ? Image.network(
                                product.imageUrl,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.fill,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) {
                                    return child;
                                  }
                                  return Container(
                                    height: 150,
                                    color: Colors.grey[200],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
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
                                      height: 150,
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
                                      height: 150,
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

                            // 2. Botão de Favorito (Coração)
                            if (product.id != null)
                              Positioned(
                                top: 5, // Posição do topo
                                right: 5, // Posição da direita
                                child: Container(
                                  decoration: const BoxDecoration(
                                    // Fundo semitransparente para melhor contraste
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      // Ícone preenchido ou com borda
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? Colors.redAccent
                                          : Colors.white,
                                      size: 24.0,
                                    ),
                                    onPressed: () =>
                                        _toggleFavorite(product.id!),
                                  ),
                                ),
                              ),
                          ],
                        ),

                        //Informações (Nome e Preço)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Nome e Preço (LADO ESQUERDO)
                              Expanded(
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
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Botão de Remover (LADO DIREITO) - Condicional ️
                              if (canDelete && product.id != null)
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _deleteProduct(product.id!),
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
