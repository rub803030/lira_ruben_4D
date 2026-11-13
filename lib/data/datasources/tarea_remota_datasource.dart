import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/tarea_model.dart';

/// Error controlado de la capa remota. Permite que la interfaz muestre un
/// mensaje claro sin conocer detalles de HTTP.
class ErrorServicioRemoto implements Exception {
  const ErrorServicioRemoto(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Fuente de datos remota (API REST).
///
/// Consume el servicio de prueba JSONPlaceholder inyectando el token JWT en
/// la cabecera `Authorization: Bearer <token>`.
class TareaRemotaDatasource {
  TareaRemotaDatasource({http.Client? cliente})
      : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  static final Uri _endpoint =
      Uri.parse('https://jsonplaceholder.typicode.com/todos');

  /// Realiza la peticion GET autenticada y mapea los primeros 5 resultados a
  /// objetos [TareaModel]. Cualquier fallo se propaga con `rethrow`.
  Future<List<TareaModel>> sincronizarTareasNube(String tokenJwt) async {
    try {
      final http.Response respuesta = await _cliente.get(
        _endpoint,
        headers: <String, String>{
          'Authorization': 'Bearer $tokenJwt',
          'Accept': 'application/json',
        },
      );

      if (respuesta.statusCode != 200) {
        throw ErrorServicioRemoto(
          'El servidor respondio con codigo ${respuesta.statusCode}. '
          'No fue posible sincronizar las tareas.',
        );
      }

      final Object? cuerpo = jsonDecode(respuesta.body);
      if (cuerpo is! List<dynamic>) {
        throw const ErrorServicioRemoto(
          'La respuesta del servidor no tiene el formato JSON esperado.',
        );
      }

      return cuerpo
          .take(5)
          .map(
            (dynamic elemento) =>
                TareaModel.fromMap(elemento as Map<String, dynamic>),
          )
          .toList(growable: false);
    } catch (_) {
      // Se captura la excepcion y se propaga intacta hacia la capa superior.
      rethrow;
    }
  }

  void cerrar() {
    _cliente.close();
  }
}
