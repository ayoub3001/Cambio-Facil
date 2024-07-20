import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../Domain/Data/constants.dart';
import '../../Domain/Data/variables.dart';
import '../../Domain/models/controllers.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  final ScrollController _scrollController = ScrollController();
  double _totalPago = 0.0;
  List<String> _resultado = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<int> _contadores = List.filled(denominaciones.length, 0);

  void _playSound() async {
    await _audioPlayer.play(AssetSource('sounds/sonido_clic.mp3'));
  }

  void _calcularCambio() {
    _playSound();
    _resultado = calcularCambio(cobrarController.text, _totalPago);
    setState(() {
      // Use a post-frame callback to ensure the scroll happens after rendering
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.easeOut,
    );
  }

  void _resetear() {
    _playSound();
    setState(() {
      cobrarController.clear();
      _totalPago = 0.0;
      _resultado = [];
      _contadores = List.filled(denominaciones.length, 0);
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.easeOut,
    );
  }

  void _agregarPago(int index) {
    _playSound();
    setState(() {
      _totalPago += denominaciones[index]['valor'];
      _contadores[index]++;
    });
  }

  void _quitarPago(int index) {
    _playSound();
    if (_contadores[index] > 0) {
      setState(() {
        _totalPago -= denominaciones[index]['valor'];
        _contadores[index]--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  margin: const EdgeInsets.only(top: 30),
                  child: const Text(
                    "CALCULADORA CAMBIOS",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  )),
            ),
            const SizedBox(
              height: 20,
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Total Productos: "),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: cobrarController,
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
              children: List.generate(denominaciones.length, (index) {
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
                          denominaciones[index]['imagen'],
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
                        const SizedBox(width: 5),
                        Text(
                          '${_contadores[index]}',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.green,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                            ),
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
                    child: GestureDetector(
                  onTap: _calcularCambio,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calculate,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Calcular",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                )),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: GestureDetector(
                  onTap: _resetear,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Resetear",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ),
                )),
              ],
            ),
            const SizedBox(height: 20),
            _resultado.isNotEmpty
                ? _resultado[0].startsWith('El pago es insuficiente.') ||
                        _resultado[0] ==
                            'Por favor, ingrese la cantidad a cobrar.' ||
                        _resultado[0] ==
                            'Formato de cantidad a cobrar inválido.'
                    ? Column(
                        children: [
                          Text(
                            _resultado[0],
                            style: const TextStyle(
                                fontSize: 18, color: Colors.red),
                          ),
                          Wrap(
                            children: _resultado
                                .sublist(1)
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
                          )
                        ],
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
