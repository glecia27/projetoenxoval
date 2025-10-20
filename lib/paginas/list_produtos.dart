import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db_service/db_service_models.dart';
import 'detalhes_page.dart';

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
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    // Inicializa o Future chamando o método do banco de dados
    _productsFuture = DatabaseService().getProducts();
  }

  // Método público para ser chamado pela GlobalKey da HomePage
  void refreshList() {
    _refreshProducts();
  }

  // Função para recarregar a lista (útil após adicionar/deletar um produto)
  void _refreshProducts() {
    setState(() {
      _productsFuture = _dbService.getProducts();
    });
  }

  //Método para lidar com a exclusão de produtos ⭐
  Future<void> _deleteProduct(int productId) async {
    // 1. Mostrar Diálogo de Confirmação
    final confirmed =
        await showDialog<bool>(
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
        false; // Garante que retorne false se o diálogo for descartado

    // 2. Se confirmado, execute a exclusão
    if (confirmed) {
      try {
        await _dbService.deleteProduct(productId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto removido com sucesso!')),
        );
        // Recarregar a lista após a exclusão
        _refreshProducts();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao remover produto: $e')));
      }
    }
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

      //Usando FutureBuilder para lidar com a busca assíncrona
      child: FutureBuilder<List<Product>>(
        future: _productsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          //Estado de Erro
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar produtos: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          //Estado Sem Dados (Lista Vazia)
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'Nenhum porduto cadastrado',
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            );
          } //Estado de Sucesso (Dados Prontos!)
          final products = snapshot.data!;

          // Verificação de Nível de Acesso
          final bool canDelete =
              widget.user.accessLevel == 'vendedor' ||
              widget.user.accessLevel == 'administrador';

          return RefreshIndicator(
            onRefresh: () async {
              _refreshProducts();
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
                          builder: (ctx) => DetalhesPage(product: product),
                        ),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Detalhes de ${product.name}')),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Imagem do Produto
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
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          height: 150,
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
                                  errorBuilder: (context, error, stackTrace) =>
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
                                  errorBuilder: (context, error, stackTrace) =>
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
