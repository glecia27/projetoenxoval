import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:projetoenxoval/paginas/registar_user.dart';
import 'package:projetoenxoval/paginas/tela_loguin.dart';

import 'db_service/db_service_models.dart';

// Lista dos níveis de acesso disponíveis, usada no cadastro
const List<String> accessLevels = ['padrao', 'vendedor', 'administrador'];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(DevicePreview(enabled: !kReleaseMode, builder: (context) => MyApp()));

  try {
    await DatabaseService().database;
    print("Banco de dados inicializado com sucesso.");

    // Adicionar um produto inicial para testes
    final service = DatabaseService();
    // Verifica se já existe um produto de teste para evitar duplicatas em cada inicialização
    final products = await service.getProducts();
    if (products.isEmpty) {
      await service.insertProduct(
        Product(
          name: 'Curso Avançado de Flutter',
          price: 99.99,
          // URL de imagem de exemplo (pode ser null para usar a imagem local)
          imageUrl:
              'https://placehold.co/400x200/5E35B1/ffffff?text=FLUTTER+PRO',
        ),
      );
      print("Produto de teste inserido.");
    }
  } catch (e) {
    print("Erro ao inicializar o banco de dados: $e");
    // Em produção, você trataria esse erro de forma mais robusta
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Projeto Enxoval',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
      ),
      home: LoginScreen(),
    );
  }
}
