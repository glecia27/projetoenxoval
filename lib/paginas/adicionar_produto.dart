import 'package:flutter/material.dart';
import '../db_service/db_service_models.dart';

// Este Widget representa a tela Modal (BottomSheet) para adicionar um novo produto.

class AdicionarProduto extends StatefulWidget {

  final VoidCallback onProductAdded;

  const AdicionarProduto({super.key, required this.onProductAdded});

  @override
  State<AdicionarProduto> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AdicionarProduto> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  Future<void> _saveProduct() async {
    // 1. Validação do Formulário
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      // Converte o texto do preço para double, tratando possíveis erros de formato.
      final price = double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;
      final imageUrl = _imageUrlController.text.trim();

      // 2. Criação do Objeto Produto
      final newProduct = Product(
        name: name,
        price: price,
        // Se a URL estiver vazia, usa null, permitindo que o modelo use a defaultImageUrl.
        imageUrl: imageUrl.isEmpty ? null : imageUrl,
      );

      try {
        // 3. Inserção no Banco de Dados
        await _dbService.insertProduct(newProduct);

        // 4. Notificação de Sucesso e Fechamento do Modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produto adicionado com sucesso!')),
        );

        // Chama o callback para que a tela de listagem recarregue os dados
        widget.onProductAdded();

        // Fecha o Modal Bottom Sheet
        Navigator.pop(context);
      } catch (e) {
        // 5. Tratamento de Erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar produto: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    // Limpa os controladores quando o widget for descartado
    _nameController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets, // Ajusta o padding para o teclado
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 5,
              blurRadius: 7,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Text(
                  'Cadastrar Novo Produto',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.pinkAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Campo Nome do Produto
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Produto',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome do produto.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Campo Preço
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Preço (R\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o preço.';
                    }
                    if (double.tryParse(value.replaceAll(',', '.')) == null) {
                      return 'Preço inválido. Use números.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Campo URL da Imagem
                TextFormField(
                  controller: _imageUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL da Imagem (Opcional)',
                    hintText: 'Ex: http://minhaimagem.com/foto.jpg',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 30),

                // Botão Salvar
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Salvar Produto',
                    style: TextStyle(fontSize: 18),
                  ),
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
