import 'package:flutter/material.dart';
import '../db_service/carrinho_model.dart';
import '../db_service/db_service_models.dart';

// --- Constantes de Frete e ICMS ---

// Lista de todos os estados brasileiros (abreviações)
const List<String> brazilianStates = <String>[
  'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA',
  'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR', 'RJ', 'RN',
  'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO'
];

// Mapa de Custo de Frete (Simulado) - Partindo de Cuiabá (MT)
const Map<String, double> shippingCosts = {
  'AC': 75.00, 'AL': 50.00, 'AM': 80.00, 'AP': 85.00, 'BA': 55.00,
  'CE': 60.00, 'DF': 25.00, 'ES': 45.00, 'GO': 20.00, 'MA': 65.00,
  'MG': 35.00, 'MS': 15.00, 'MT': 0.00,
  'PA': 70.00, 'PB': 55.00, 'PE': 50.00, 'PI': 60.00, 'PR': 30.00,
  'RJ': 40.00, 'RN': 55.00, 'RO': 70.00, 'RR': 90.00, 'RS': 45.00,
  'SC': 40.00, 'SE': 50.00, 'SP': 35.00, 'TO': 25.00,
};

// Mapa de Alíquotas Internas Padrão de ICMS (em formato decimal)
// Baseado em alíquotas internas padrão de 2024/2025 para simulação.
const Map<String, double> icmsRates = {
  'AC': 0.19, 'AL': 0.19, 'AM': 0.20, 'AP': 0.18, 'BA': 0.205,
  'CE': 0.20, 'DF': 0.20, 'ES': 0.17, 'GO': 0.19, 'MA': 0.22,
  'MG': 0.18, 'MS': 0.17, 'MT': 0.17, // Alíquota interna de MT
  'PA': 0.19, 'PB': 0.20, 'PE': 0.205, 'PI': 0.21, 'PR': 0.195,
  'RJ': 0.22, 'RN': 0.18, 'RO': 0.195, 'RR': 0.20, 'RS': 0.17,
  'SC': 0.17, 'SE': 0.19, 'SP': 0.18, 'TO': 0.20,
};

class CarrinhoPage extends StatefulWidget {
  final User user;
  const CarrinhoPage({super.key, required this.user});

  @override
  State<CarrinhoPage> createState() => _CarrinhoPageState();
}

class _CarrinhoPageState extends State<CarrinhoPage> {
  // Instância do serviço de banco de dados
  final DatabaseService _dbService = DatabaseService();

  // --- Variáveis de Estado para Frete e ICMS ---
  String? _selectedState = 'SP';
  double _shippingCost = shippingCosts['SP'] ?? 0.00;
  // Nova variável para o ICMS
  double _icmsCost = 0.00;

  @override
  void initState() {
    super.initState();
    // O cálculo inicial será feito no FutureBuilder após carregar o subtotal,
    // mas garantimos que o estado inicial tenha o frete correto.
    _calculateShippingCost(_selectedState, 0.0); // Passamos 0.0 como subtotal inicial
  }

  // Função para carregar os dados do carrinho
  Future<List<CarrinhoModel>> _loadCartItems() async {
    return await _dbService.getShoppingList(widget.user.id);
  }

  // Função para remover um item e atualizar a UI
  void _removeItem(int itemId) async {
    await _dbService.removeShoppingListItem(itemId);
    // Força a reconstrução da UI para recarregar a lista e recalcular os custos
    setState(() {});
  }

  // Função para limpar o carrinho inteiro
  void _clearCart() async {
    await _dbService.clearShoppingList(widget.user.id);
    setState(() {});
  }

  // Função atualizada para calcular Frete E ICMS com base no estado e subtotal
  void _calculateShippingCost(String? state, double subtotal) {
    double newShippingCost = shippingCosts[state] ?? 0.00;
    double newIcmsCost = 0.00;

    // 1. Calcula o ICMS
    if (state != null && icmsRates.containsKey(state)) {
      final double aliquot = icmsRates[state]!;
      // Cálculo "por fora" do ICMS: (Subtotal / (1 - Alíquota)) - Subtotal
      // Assumimos que o subtotal *não* inclui ICMS para o cálculo aqui.
      if (aliquot < 1.0) {
        newIcmsCost = (subtotal / (1.0 - aliquot)) - subtotal;
      }
    }

    // 2. Atualiza o estado
    setState(() {
      _selectedState = state;
      _shippingCost = newShippingCost;
      _icmsCost = newIcmsCost > 0 ? newIcmsCost : 0.00; // Garante que não seja negativo
    });
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

            // Cálculo do Subtotal dos Itens
            final double subtotal = items.fold(
              0.0,
                  (sum, item) => sum + (item.price * item.quantity),
            );

            // Chamar o cálculo do frete e ICMS *após* ter o subtotal
            // Este é um truque comum no FutureBuilder, embora não ideal para grandes mudanças
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Verifica se o valor atual do ICMS é diferente do valor que deveria ser,
              // forçando o recálculo apenas se necessário (otimização)
              final double expectedIcmsCost = icmsRates.containsKey(_selectedState)
                  ? (subtotal / (1.0 - icmsRates[_selectedState]!)) - subtotal
                  : 0.0;

              if (_icmsCost.toStringAsFixed(2) != expectedIcmsCost.toStringAsFixed(2)) {
                _calculateShippingCost(_selectedState, subtotal);
              }
            });

            // Cálculo do Total Geral (Subtotal + Frete + ICMS)
            // Assumimos que o ICMS deve ser adicionado ao subtotal *antes* de somar o frete para o Total Geral
            final double total = subtotal + _icmsCost + _shippingCost;


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
                _buildTotalSummary(context, subtotal, total),
              ],
            );
          },
        ),
      ),
    );
  }

  // Widget para construir cada item do carrinho (Inalterado)
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
  Widget _buildTotalSummary(BuildContext context, double subtotal, double total) {
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
          // Seleção de Estado (Frete e ICMS)
          _buildShippingSelector(context, subtotal),
          const SizedBox(height: 8),

          // Subtotal (Valor dos produtos sem impostos)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal (Itens):',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                'R\$ ${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Frete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Frete:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              Text(
                _shippingCost == 0.00
                    ? 'Grátis'
                    : 'R\$ ${_shippingCost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _shippingCost == 0.00 ? Colors.green : Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // ICMS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ICMS (${(icmsRates[_selectedState]! * 100).toStringAsFixed(1)}%):',
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
              Text(
                'R\$ ${_icmsCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),

          //Total Geral
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Geral:',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'R\$ ${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.pink,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          //Botão Finalizar Compra
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Finalizando compra para $_selectedState. Total: R\$ ${total.toStringAsFixed(2)} (ICMS: R\$ ${_icmsCost.toStringAsFixed(2)})',
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

  // Widget para seleção do estado de destino (Atualizado para passar subtotal)
  Widget _buildShippingSelector(BuildContext context, double subtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecione o Estado de Destino:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          value: _selectedState,
          hint: const Text('Selecione o Estado'),
          icon: const Icon(Icons.arrow_drop_down),
          elevation: 16,
          style: const TextStyle(color: Colors.deepPurple, fontSize: 16),
          onChanged: (String? newValue) {
            // Chama a função de cálculo passando o novo estado e o subtotal atual
            _calculateShippingCost(newValue, subtotal);
          },
          items: brazilianStates.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}