import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
  Wakelock.enable(); // Mantener la pantalla encendida
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Cambio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final _cobrarController = TextEditingController();
  double _totalPago = 0.0;
  List<String> _resultado = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  final List<Map<String, dynamic>> _denominaciones = [
    {'valor': 50.0, 'imagen': 'assets/images/50_euro.png'},
    {'valor': 20.0, 'imagen': 'assets/images/20_euro.png'},
    {'valor': 10.0, 'imagen': 'assets/images/10_euro.png'},
    {'valor': 5.0, 'imagen': 'assets/images/5_euro.png'},
    {'valor': 2.0, 'imagen': 'assets/images/2_euro.png'},
    {'valor': 1.0, 'imagen': 'assets/images/1_euro.png'},
    {'valor': 0.50, 'imagen': 'assets/images/50_centimo.png'},
    {'valor': 0.20, 'imagen': 'assets/images/20_centimo.png'},
    {'valor': 0.10, 'imagen': 'assets/images/10_centimo.png'},
    {'valor': 0.05, 'imagen': 'assets/images/5_centimo.png'},
    {'valor': 0.02, 'imagen': 'assets/images/2_centimo.png'},
    {'valor': 0.01, 'imagen': 'assets/images/1_centimo.png'},
  ];

  List<int> _contadores = List.filled(12, 0);

  void _playSound() async {
    await _audioPlayer.play(AssetSource('sounds/sonido_clic.mp3'));
  }

  void _calcularCambio() {
    _playSound();
    if (_cobrarController.text.isEmpty) {
      setState(() {
        _resultado = ['Por favor, ingrese la cantidad a cobrar.'];
      });
      return;
    }

    String cobrarText = _cobrarController.text.replaceAll(',', '.');
    double cobrar;
    try {
      cobrar = double.parse(cobrarText);
    } catch (e) {
      setState(() {
        _resultado = ['Formato de cantidad a cobrar inválido.'];
      });
      return;
    }

    double cambio = _totalPago - cobrar;

    if (cambio < 0) {
      setState(() {
        _resultado = ['El pago es insuficiente.'];
      });
      return;
    }

    List<String> cambioDevuelto = [];

    for (var denominacion in _denominaciones) {
      while (cambio >= denominacion['valor']) {
        cambioDevuelto.add(denominacion['imagen']);
        cambio -= denominacion['valor'];
        cambio = double.parse(
            cambio.toStringAsFixed(2)); // Evitar problemas de precisión
      }
    }

    setState(() {
      _resultado = cambioDevuelto;
    });
  }

  void _agregarPago(int index) {
    _playSound();
    setState(() {
      _totalPago += _denominaciones[index]['valor'];
      _contadores[index]++;
    });
  }

  void _quitarPago(int index) {
    _playSound();
    if (_contadores[index] > 0) {
      setState(() {
        _totalPago -= _denominaciones[index]['valor'];
        _contadores[index]--;
      });
    }
  }

  void _resetear() {
    _playSound();
    setState(() {
      _cobrarController.clear();
      _totalPago = 0.0;
      _resultado = [];
      _contadores = List.filled(12, 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Cambio'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _cobrarController,
              decoration: const InputDecoration(
                labelText: 'Cantidad a cobrar (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            Text(
              'Dinero del cliente: €$_totalPago',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_denominaciones.length, (index) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => _agregarPago(index),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _contadores[index] > 0
                                ? Colors.green
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Image.asset(
                          _denominaciones[index]['imagen'],
                          width: 150,
                          height: 75,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.red,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () => _quitarPago(index),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          '${_contadores[index]}',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.green,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () => _agregarPago(index),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _calcularCambio,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calcular'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      textStyle: const TextStyle(fontSize: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetear,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Resetear'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      textStyle: const TextStyle(fontSize: 20),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _resultado.isNotEmpty
                ? _resultado[0] == 'El pago es insuficiente.' ||
                        _resultado[0] ==
                            'Por favor, ingrese la cantidad a cobrar.' ||
                        _resultado[0] ==
                            'Formato de cantidad a cobrar inválido.'
                    ? Text(
                        _resultado[0],
                        style: const TextStyle(fontSize: 18, color: Colors.red),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: _resultado
                              .map((imgPath) => Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Image.asset(
                                      imgPath,
                                      width: 150,
                                      height: 75,
                                      fit: BoxFit.contain,
                                    ),
                                  ))
                              .toList(),
                        ),
                      )
                : Container(),
          ],
        ),
      ),
    );
  }
}
