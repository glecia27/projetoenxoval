import 'package:flutter/material.dart';
import '../db_service/db_service_models.dart';
import '../main.dart'; // Para acessar a lista global de accessLevels

// =========================================================
// TELA DE REGISTRO
// =========================================================

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Valor inicial do nível de acesso (usa a lista de accessLevels do main.dart)
  String _selectedAccessLevel = accessLevels.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Função auxiliar para mostrar feedback
  void _showSnackbar(String message, {required bool success}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Função principal para realizar o registro
  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final username = _usernameController.text;
      final password = _passwordController.text;

      try {
        final userId = await DatabaseService().registerUser(
          username,
          password,
          _selectedAccessLevel,
        );

        if (userId > 0) {
          _showSnackbar('Usuário "$username" registrado com sucesso! Nível: $_selectedAccessLevel', success: true);
          // Limpa os campos após o sucesso
          _usernameController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
          setState(() {
            _selectedAccessLevel = accessLevels.first; // Volta ao padrão
          });

          // Navega de volta para o Login após registro
          Navigator.pop(context);

        } else {
          _showSnackbar('Falha ao registrar usuário. Tente outro nome.', success: false);
        }
      } catch (e) {
        // Captura erros como nome de usuário duplicado (UNIQUE constraint)
        _showSnackbar('Erro: Nome de usuário já existe ou falha no DB. $e', success: false);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de Usuário'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.shade100,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Criar Nova Conta',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Campo Nome de Usuário
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome de Usuário',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira um nome de usuário.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Senha
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo Confirmação de Senha
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Seletor de Nível de Acesso (Dropdown)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedAccessLevel,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple, fontSize: 16),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedAccessLevel = newValue!;
                          });
                        },
                        items: accessLevels.map<DropdownMenuItem<String>>((String value) {
                          // Converte a primeira letra para maiúscula para exibição
                          String displayValue = value.substring(0, 1).toUpperCase() + value.substring(1);
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text('Nível: $displayValue'),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Botão de Registro
                  ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                        : const Text(
                      'Registrar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Os níveis de acesso são: Padrão, Vendedor ou Administrador.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 10),

                  // Botão para voltar para o Login
                  TextButton(
                    onPressed: () {
                      // Usa pop para voltar para a tela anterior (LoginScreen)
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Já tem conta? Fazer Login',
                      style: TextStyle(color: Colors.deepPurple),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
