import 'package:flutter/material.dart';

import '../data/datasources/tarea_local_dao.dart';
import '../data/datasources/tarea_remota_datasource.dart';
import '../data/repositories/tarea_repositorio.dart';
import 'pages/tareas_page.dart';

/// Punto de composicion de la aplicacion.
///
/// Aqui se inyectan las dependencias de la capa `data` en la capa de
/// presentacion. Los widgets nunca construyen un DAO ni un cliente HTTP.
class LiraRubenApp extends StatefulWidget {
  const LiraRubenApp({super.key});

  @override
  State<LiraRubenApp> createState() => _LiraRubenAppState();
}

class _LiraRubenAppState extends State<LiraRubenApp> {
  late final TareaRepositorio _repositorio;

  @override
  void initState() {
    super.initState();
    _repositorio = TareaRepositorio(
      TareaLocalDao(),
      TareaRemotaDatasource(),
    );
  }

  @override
  void dispose() {
    _repositorio.cerrar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color semilla = Color(0xFF4F46E5);

    return MaterialApp(
      title: 'Lira Ruben 4D - Persistencia SQLite',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: semilla,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: TareasPage(repositorio: _repositorio),
    );
  }
}
