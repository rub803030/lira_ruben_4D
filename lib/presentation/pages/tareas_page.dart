import 'package:flutter/material.dart';

import '../../data/models/tarea_model.dart';
import '../../data/repositories/tarea_repositorio.dart';
import 'sincronizacion_page.dart';

/// Pantalla principal: lista las tareas pendientes almacenadas en SQLite y
/// permite insertar nuevas tareas.
///
/// Toda la persistencia se delega al repositorio; aqui no existe ninguna
/// sentencia SQL ni peticion HTTP.
class TareasPage extends StatefulWidget {
  const TareasPage({super.key, required this.repositorio});

  final TareaRepositorio repositorio;

  @override
  State<TareasPage> createState() => _TareasPageState();
}

class _TareasPageState extends State<TareasPage> {
  late Future<List<TareaModel>> _tareasFuture;

  @override
  void initState() {
    super.initState();
    _tareasFuture = widget.repositorio.obtenerTareasPendientes();
  }

  void _recargar() {
    setState(() {
      _tareasFuture = widget.repositorio.obtenerTareasPendientes();
    });
  }

  Future<void> _mostrarFormulario() async {
    final String? titulo = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => const _FormularioTareaDialog(),
    );

    if (titulo == null || titulo.isEmpty || !mounted) {
      return;
    }

    await widget.repositorio.crearTarea(titulo);
    if (!mounted) {
      return;
    }
    _recargar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"$titulo" se guardo en la memoria Flash.'),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  Future<void> _completarTarea(TareaModel tarea) async {
    await widget.repositorio.alternarCompletada(tarea);
    if (!mounted) {
      return;
    }
    _recargar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${tarea.titulo}" se marco como completada.'),
      ),
    );
  }

  Future<void> _eliminarTarea(TareaModel tarea) async {
    await widget.repositorio.eliminarTarea(tarea.id!);
    if (!mounted) {
      return;
    }
    _recargar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tarea eliminada de SQLite.')),
    );
  }

  Future<void> _abrirNube() async {
    final bool? cambio = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => SincronizacionPage(
          repositorio: widget.repositorio,
        ),
      ),
    );
    if (cambio == true && mounted) {
      _recargar();
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
              'Mis tareas',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            Text(
              'SQLite  ·  tareas_offline.db',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Consumir servicio web',
            onPressed: _abrirNube,
            icon: const Icon(Icons.cloud_sync_outlined),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormulario,
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
      ),
      body: Column(
        children: <Widget>[
          _BannerPersistencia(colores: colores),
          Expanded(
            child: FutureBuilder<List<TareaModel>>(
              future: _tareasFuture,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<TareaModel>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _Cargando();
                }
                if (snapshot.hasError) {
                  return _Error(
                    mensaje: snapshot.error.toString(),
                    onReintentar: _recargar,
                  );
                }

                final List<TareaModel> tareas =
                    snapshot.data ?? const <TareaModel>[];
                if (tareas.isEmpty) {
                  return const _EstadoVacio();
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: tareas.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (BuildContext context, int index) {
                    final TareaModel tarea = tareas[index];
                    return _TarjetaTarea(
                      tarea: tarea,
                      indice: index + 1,
                      onCompletar: () => _completarTarea(tarea),
                      onEliminar: () => _eliminarTarea(tarea),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerPersistencia extends StatelessWidget {
  const _BannerPersistencia({required this.colores});

  final ColorScheme colores;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: <Color>[
            colores.primary,
            colores.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.sd_storage_rounded, color: Colors.white, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Persistencia activa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Cada tarea se graba en la memoria Flash del dispositivo.',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaTarea extends StatelessWidget {
  const _TarjetaTarea({
    required this.tarea,
    required this.indice,
    required this.onCompletar,
    required this.onEliminar,
  });

  final TareaModel tarea;
  final int indice;
  final VoidCallback onCompletar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colores = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colores.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colores.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colores.primaryContainer,
          foregroundColor: colores.onPrimaryContainer,
          child: Text(
            indice.toString(),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(
          tarea.titulo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Pendiente  ·  ID #${tarea.id}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              tooltip: 'Eliminar',
              onPressed: onEliminar,
              icon: Icon(Icons.delete_outline, color: colores.error),
            ),
            Checkbox(
              value: false,
              onChanged: (_) => onCompletar(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Cargando tareas desde SQLite...'),
        ],
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.playlist_add_check_circle_outlined,
              size: 84,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay tareas pendientes',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Toca "Nueva tarea" para crear la primera.\nSe conservara aunque cierres la aplicacion.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'No se pudo acceder a SQLite',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formulario con estado propio para que el [TextEditingController] viva
/// exactamente lo mismo que la ruta del dialogo y se libere al finalizar la
/// animacion de cierre.
class _FormularioTareaDialog extends StatefulWidget {
  const _FormularioTareaDialog();

  @override
  State<_FormularioTareaDialog> createState() => _FormularioTareaDialogState();
}

class _FormularioTareaDialogState extends State<_FormularioTareaDialog> {
  final TextEditingController _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _guardar() {
    final String limpio = _controlador.text.trim();
    if (limpio.isNotEmpty) {
      Navigator.of(context).pop(limpio);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.playlist_add_rounded),
      title: const Text('Nueva tarea'),
      content: TextField(
        controller: _controlador,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: const InputDecoration(
          labelText: 'Titulo de la tarea',
          hintText: 'Ej. Estudiar persistencia SQLite',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _guardar(),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controlador,
          builder: (BuildContext context, TextEditingValue valor, _) {
            return FilledButton(
              onPressed: valor.text.trim().isEmpty ? null : _guardar,
              child: const Text('Guardar'),
            );
          },
        ),
      ],
    );
  }
}
