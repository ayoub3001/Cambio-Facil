// ignore_for_file: file_names

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../Domain/Data/variables.dart';

class RegistroProductos extends StatefulWidget {
  const RegistroProductos({super.key});

  @override
  RegistroProductosState createState() => RegistroProductosState();
}

class RegistroProductosState extends State<RegistroProductos> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _offerController = TextEditingController();
  String _barcode = "";
  final Map<String, List<String>> _products = {};
  final Map<String, List<String>> _existingProducts = {};
  bool _isLoading = false;

  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://carniceria-amin-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref().child(codeDB).child("Productos");

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> scanBarcode() async {
    String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'Cancelar', true, ScanMode.BARCODE);
    if (barcodeScanRes != '-1') {
      await _audioPlayer.play(AssetSource('sounds/sound_scanner.mp3'));
    }
    setState(() {
      _barcode = barcodeScanRes != '-1' ? barcodeScanRes : '';
    });
  }

  void saveProduct() {
    if (_barcode.isNotEmpty &&
        _nameController.text.isNotEmpty &&
        _priceController.text.isNotEmpty) {
      if (!_products.containsKey(_barcode)) {
        double price = double.parse(_priceController.text.replaceAll(',', '.'));
        String formattedPrice = '${price.toStringAsFixed(2)}€';
        String offer =
            _offerController.text.isNotEmpty ? _offerController.text : 'N/A';
        setState(() {
          _products[_barcode] = [_nameController.text, formattedPrice, offer];
          _nameController.clear();
          _priceController.clear();
          _offerController.clear();
          _barcode = "";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Este producto ya ha sido registrado.')));
      }
    }
  }

  void clearProduct() {
    setState(() {
      _nameController.clear();
      _priceController.clear();
      _offerController.clear();
      _barcode = "";
    });
  }

  void deleteProduct(String barcode) {
    setState(() {
      _products.remove(barcode);
    });
  }

  Future<void> fetchExistingProducts() async {
    DataSnapshot snapshot = await _dbRef.get();
    if (snapshot.exists) {
      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);
      data.forEach((key, value) {
        if (value is Map) {
          _existingProducts[key] = [
            value['name'].toString(),
            value['price'].toString(),
            value['offer']?.toString() ?? 'N/A',
          ];
        }
      });
    }
  }

  Future<void> sendToRealtimeDatabase() async {
    setState(() {
      _isLoading = true;
    });

    await fetchExistingProducts();
    for (var barcode in _products.keys) {
      if (_existingProducts.containsKey(barcode)) {
        String existingName = _existingProducts[barcode]![0];
        String existingPrice = _existingProducts[barcode]![1];
        String newPrice = _products[barcode]![1];
        String newOffer = _products[barcode]![2];
        if (existingPrice != newPrice) {
          await _dbRef.child(barcode).update({
            'name': existingName,
            'price': newPrice,
            'offer': newOffer,
          });
        }
      } else {
        await _dbRef.child(barcode).set({
          'name': _products[barcode]![0],
          'price': _products[barcode]![1],
          'offer': _products[barcode]![2],
        });
      }
    }
    setState(() {
      _products.clear();
      _isLoading = false;
    });

    // Mostrar un AlertDialog al subir los datos exitosamente
    showSuccessDialog();
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Éxito"),
          content: const Text("Los productos se han subido exitosamente."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Productos'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: scanBarcode,
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 35),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.purple),
                      child: const Text(
                        "Escanear código de barras",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _barcode.isNotEmpty
                        ? 'Código escaneado: $_barcode'
                        : 'No hay código escaneado.',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nombre del Producto'),
                  ),
                  TextField(
                    controller: _priceController,
                    decoration:
                        const InputDecoration(labelText: 'Precio del Producto'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _offerController,
                    decoration: const InputDecoration(
                        labelText: 'Oferta (Ej: 3x1€, 2x1€)'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: saveProduct,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text(
                              "Guardar producto",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: clearProduct,
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Text(
                              "Borrar Datos",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 200,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black, width: 1.0),
                      ),
                      child: ListView.separated(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          String barcode = _products.keys.elementAt(index);
                          String name = _products[barcode]![0];
                          String price = _products[barcode]![1];
                          String offer = _products[barcode]![2];
                          return ListTile(
                            title: Text(
                                '$name: $price ; $barcode ; Oferta: $offer'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteProduct(barcode),
                            ),
                          );
                        },
                        separatorBuilder: (context, index) => const Divider(
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: sendToRealtimeDatabase,
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 35),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.purple),
                      child: const Text(
                        "Enviar a la Base de Datos",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
