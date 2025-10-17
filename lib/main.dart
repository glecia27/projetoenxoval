import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io'; // Necessário para usar Platform.is...

import 'package:projetoenxoval/paginas/registar_user.dart';
import 'package:projetoenxoval/paginas/tela_loguin.dart';

import 'db_service/db_service_models.dart';

const List<String> accessLevels = ['padrao', 'vendedor', 'administrador'];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Inicialize o driver do SQLite FFI antes de qualquer acesso ao banco
  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      print("✅ SQFLite FFI: Driver inicializado para plataforma desktop.");
    }
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
          name: 'Curso Avançado de Flutter',
          price: 99.99,
          imageUrl:
              'https://placehold.co/400x200/5E35B1/ffffff?text=FLUTTER+PRO',
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
