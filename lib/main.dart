import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:projetoenxoval/paginas/tela_loguin.dart';
import 'db_service/db_service_models.dart';

const List<String> accessLevels = ['padrao', 'vendedor', 'administrador'];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Inicializar o SQLite apenas para plataformas desktop
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    sqfliteFfiInit();
    sqflite.databaseFactory = databaseFactoryFfi;
    print("✅ SQFLite FFI: Driver inicializado para plataforma desktop.");
  } else {
    print(
      "✅ SQFLite: Usando driver nativo para Android/iOS ou outras plataformas.",
    );
  }

  try {
    // 🔹 Inicializa o serviço de banco de dados
    final dbService = DatabaseService();

    // 🔹 Garante que o banco será aberto/criado antes de continuar
    await dbService.database;
    print("✅ Banco de dados inicializado com sucesso.");

    // 🔹 Inserção de produto de teste, apenas se o banco estiver vazio
    final products = await dbService.getProducts();
    if (products.isEmpty) {
      await dbService.insertProduct(
        Product(
          name: 'Roupinhas DEMO',
          price: 25.99,
          imageUrl:
              'https://img.elo7.com.br/product/zoom/4961500/saida-maternidade-menino-enxoval-masculino-roupa-bebe.jpg',
        ),
      );
      print("🧩 Produto de teste inserido.");
    }
  } catch (e) {
    print("❌ Erro ao inicializar o banco de dados: $e");
  }

  // 🔹 Inicia o aplicativo
  runApp(DevicePreview(enabled: false, builder: (context) => const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'Coisa Fofa Exoval',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
      home: TelaLoguin(),
    );
  }
}
