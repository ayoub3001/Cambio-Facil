import '../Data/constants.dart';

List<String> calcularCambio(String cobrarText, double totalPago) {
  if (cobrarText.isEmpty) {
    return ['Por favor, ingrese la cantidad a cobrar.'];
  }

  cobrarText = cobrarText.replaceAll(',', '.');
  double cobrar;
  try {
    cobrar = double.parse(cobrarText);
  } catch (e) {
    return ['Formato de cantidad a cobrar inválido.'];
  }

  double cambio = totalPago - cobrar;

  if (cambio < 0) {
    List<String> faltanteImagenes = [];
    double faltante = -cambio;

    for (var denominacion in denominaciones) {
      while (faltante >= denominacion['valor']) {
        faltanteImagenes.add(denominacion['imagen']);
        faltante -= denominacion['valor'];
        faltante = double.parse(
            faltante.toStringAsFixed(2)); // Evitar problemas de precisión
      }
    }

    return ['El pago es insuficiente. Falta:'] + faltanteImagenes;
  }

  List<String> cambioDevuelto = [];

  for (var denominacion in denominaciones) {
    while (cambio >= denominacion['valor']) {
      cambioDevuelto.add(denominacion['imagen']);
      cambio -= denominacion['valor'];
      cambio = double.parse(
          cambio.toStringAsFixed(2)); // Evitar problemas de precisión
    }
  }

  return cambioDevuelto;
}
