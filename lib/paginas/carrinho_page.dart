import 'package:flutter/material.dart';
import '../db_service/carrinho_model.dart';
import '../db_service/db_service_models.dart';

class CarrinhoPage extends StatefulWidget {
  final User user;
  const CarrinhoPage({super.key, required this.user});

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  // Instância do serviço de banco de dados
  final DatabaseService _dbService = DatabaseService();

  // Função para carregar os dados do carrinho
  Future<List<CarrinhoModel>> _loadCartItems() async {
    return await _dbService.getShoppingList(widget.user.id);
  }

  // Função para remover um item e atualizar a UI
  void _removeItem(int itemId) async {
    await _dbService.removeShoppingListItem(itemId);
    // Força a reconstrução da UI para recarregar a lista
    setState(() {});
  }

  // Função para limpar o carrinho inteiro
  void _clearCart() async {
    await _dbService.clearShoppingList(widget.user.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Carrinho de Compras'),
        backgroundColor: const Color(0xFFE494E5),
        actions: [
          // Botão para limpar o carrinho
          TextButton.icon(
            onPressed: _clearCart,
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            label: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      // Seu gradiente agora envolve o Scaffold para preencher a tela
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE494E5), Color(0xFFE09FE5), Color(0xFFFFFFE5)],
            stops: [0.2, 0.3, 0.9],
          ),
        ),
        child: FutureBuilder<List<CarrinhoModel>>(
          future: _loadCartItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('Erro ao carregar o carrinho: ${snapshot.error}'),
              );
            }

            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Center(
                child: Text(
                  'Seu carrinho está vazio!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              );
            }

            // Cálculo do Total
            final double total = items.fold(
              0.0,
              (sum, item) => sum + (item.price * item.quantity),
            );

            return Column(
              children: [
                // Lista de Itens
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                      bottom: 80.0,
                    ), // Padding inferior para o total
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildCartItemCard(context, item);
                    },
                  ),
                ),

                // Resumo do Total (Fixo na parte inferior)
                _buildTotalSummary(context, total),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget para construir cada item do carrinho
  Widget _buildCartItemCard(BuildContext context, CarrinhoModel item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          vertical: 8.0,
          horizontal: 16.0,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 60,
            height: 80,
            color: Colors.grey[200],
            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/placeholder.png',
                        fit: BoxFit.cover,
                      );
                    },
                  )
                : Image.asset(
                    'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preço unitário: R\$ ${item.price.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              'Quantidade: ${item.quantity}x',
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'R\$ ${(item.price * item.quantity).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
              ),
              onPressed: () {
                if (item.id != null) {
                  _removeItem(item.id!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget para o resumo do total
  Widget _buildTotalSummary(BuildContext context, double total) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
              ),
              Text(
                'R\$ ${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar a lógica de finalização de compra / checkout
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Função de Finalizar Compra ainda não implementada!',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE494E5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.payment, color: Colors.white),
              label: const Text(
                'Finalizar Compra',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
