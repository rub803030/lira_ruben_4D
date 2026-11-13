import 'package:flutter/material.dart';

import '../../data/models/tarea_model.dart';
import '../../data/repositories/tarea_repositorio.dart';

/// Pantalla de consumo del servicio web.
///
/// Demuestra la inyeccion de la cabecera `Authorization: Bearer <token>` y la
/// decodificacion JSON, siempre a traves del repositorio (nunca HTTP directo
/// desde el widget).
class SincronizacionPage extends StatefulWidget {
  const SincronizacionPage({super.key, required this.repositorio});

  final TareaRepositorio repositorio;

  @override
  State<SincronizacionPage> createState() => _SincronizacionPageState();
}

class _SincronizacionPageState extends State<SincronizacionPage> {
  static const String _tokenSimulado =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJsaXJhLXJ1YmVuIiwiaWF0IjoxNzYzMDAwMDAwfQ.firma-demo';

  final TextEditingController _tokenController =
      TextEditingController(text: _tokenSimulado);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Future<List<TareaModel>>? _tareasRemotas;
  bool _importando = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _consultar() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _tareasRemotas = widget.repositorio.sincronizarTareasNube(
        _tokenController.text.trim(),
      );
    });
  }

  Future<void> _importar() async {
    setState(() => _importando = true);
    try {
      final int importadas = await widget.repositorio.importarTareasNube(
        _tokenController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            importadas == 0
                ? 'Las tareas de la nube ya estaban guardadas en SQLite.'
                : 'Se importaron $importadas tareas a SQLite.',
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.of(context).pop(importadas > 0);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _importando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al importar: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colores.surface,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Servicio web',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            Text(
              'API REST  ·  JSONPlaceholder',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _TarjetaSeguridad(colores: colores),
              const SizedBox(height: 12),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _tokenController,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Token JWT (simulado)',
                    helperText:
                        'Se envia como Authorization: Bearer <token>',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.key_outlined),
                  ),
                  validator: (String? valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Ingresa un token JWT para autenticar la peticion.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _consultar,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Ejecutar GET autenticado'),
              ),
              const SizedBox(height: 16),
              Expanded(child: _construirResultado(colores)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _construirResultado(ColorScheme colores) {
    if (_tareasRemotas == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.cloud_queue_rounded, size: 72, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Presiona el boton para consultar\nlos primeros 5 registros de la API.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<TareaModel>>(
      future: _tareasRemotas,
      builder: (
        BuildContext context,
        AsyncSnapshot<List<TareaModel>> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Conectando con https://jsonplaceholder.typicode.com...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Card(
              color: colores.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.cloud_off_rounded,
                      size: 54,
                      color: colores.onErrorContainer,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Fallo la sincronizacion',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colores.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colores.onErrorContainer),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _consultar,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final List<TareaModel> tareas =
            snapshot.data ?? const <TareaModel>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'HTTP 200  ·  ${tareas.length} tareas recibidas con JWT',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: tareas.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (BuildContext context, int index) {
                  final TareaModel tarea = tareas[index];
                  return ListTile(
                    tileColor: colores.surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: colores.outlineVariant),
                    ),
                    leading: CircleAvatar(
                      backgroundColor: colores.secondaryContainer,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(tarea.titulo),
                    subtitle: Text(
                      'ID remoto: ${tarea.id}  ·  '
                      '${tarea.completada ? "completada" : "pendiente"}',
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _importando ? null : _importar,
              icon: _importando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_alt_rounded),
              label: Text(
                _importando
                    ? 'Importando a SQLite...'
                    : 'Importar estas tareas a SQLite',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TarjetaSeguridad extends StatelessWidget {
  const _TarjetaSeguridad({required this.colores});

  final ColorScheme colores;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colores.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lock_outline, color: colores.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Peticion autenticada',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colores.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'GET /todos',
            style: TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          Text(
            'Authorization: Bearer \$tokenJwt',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: colores.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
