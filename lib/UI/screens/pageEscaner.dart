// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../Domain/Data/variables.dart';
import 'registrosProductos.dart';

class PageEscaner extends StatefulWidget {
  const PageEscaner({Key? key}) : super(key: key);

  @override
  PageEscanerState createState() => PageEscanerState();
}

class PageEscanerState extends State<PageEscaner> {
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://carniceria-amin-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref().child('productos');

  String barcode = "No hay código escaneado.";
  Map<String, Map<String, String>> existingProducts = {};

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    fetchExistingProducts();
  }

  Future<void> fetchExistingProducts() async {
    DataSnapshot snapshot = await _dbRef.get();
    if (snapshot.exists) {
      Map<String, dynamic> data =
          Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        data.forEach((key, value) {
          if (value is Map) {
            existingProducts[key] = {
              'name': value['name'].toString(),
              'price': value['price'].toString(),
              'offer': value['offer']?.toString() ?? 'N/A',
            };
          }
        });
      });
    }
  }

  Future<void> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancelar', true, ScanMode.BARCODE);
      if (barcodeScanRes != '-1') {
        await _audioPlayer.play(AssetSource('sounds/sound_scanner.mp3'));
      }
    } catch (e) {
      barcodeScanRes = 'Error al escanear el código de barras.';
    }

    if (!mounted) return;

    setState(() {
      barcode = barcodeScanRes != '-1' ? barcodeScanRes : "Escaneo cancelado.";
    });

    if (barcode != "Escaneo cancelado." &&
        barcode != "Error al escanear el código de barras.") {
      searchProduct(barcode);
    }
  }

  Future<void> scanBarcodeForRemoval() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancelar', true, ScanMode.BARCODE);
      if (barcodeScanRes != '-1') {
        await _audioPlayer.play(AssetSource('sounds/sound_scanner.mp3'));
      }
    } catch (e) {
      barcodeScanRes = 'Error al escanear el código de barras.';
    }

    if (!mounted) return;

    setState(() {
      barcode = barcodeScanRes != '-1' ? barcodeScanRes : "Escaneo cancelado.";
    });

    if (barcode != "Escaneo cancelado." &&
        barcode != "Error al escanear el código de barras.") {
      removeProduct(barcode);
    }
  }

  void searchProduct(String barcode) {
    if (existingProducts.containsKey(barcode)) {
      Map<String, String> productInfo = existingProducts[barcode]!;
      showProductDialog(barcode, productInfo['name']!, productInfo['price']!,
          productInfo['offer']!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Producto no encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
      );
      setState(() {
        barcode = "No hay código escaneado.";
      });
    }
  }

  void removeProduct(String barcode) {
    setState(() {
      if (scannedProducts.containsKey(barcode)) {
        if (int.parse(scannedProducts[barcode]!['quantity']!) > 1) {
          scannedProducts[barcode]!['quantity'] =
              (int.parse(scannedProducts[barcode]!['quantity']!) - 1)
                  .toString();
        } else {
          scannedProducts.remove(barcode);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Producto no encontrado en la lista.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
        );
      }
      barcode = "No hay código escaneado."; // Reset barcode text
    });
  }

  void removeAllProducts() {
    setState(() {
      scannedProducts.clear();
      priceProducts = 0.0;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Todos los productos han sido eliminados.')),
      );
      barcode = "No hay código escaneado."; // Reset barcode text
    });
  }

  void showProductDialog(
      String barcode, String name, String price, String offer) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Información del Producto"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nombre: $name"),
              Text("Código: $barcode"),
              const SizedBox(height: 8.0),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  "Precio: $price",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Regresar"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        setState(() {
                          if (scannedProducts.containsKey(barcode)) {
                            scannedProducts[barcode]!['quantity'] = (int.parse(
                                        scannedProducts[barcode]![
                                            'quantity']!) +
                                    1)
                                .toString();
                          } else {
                            scannedProducts[barcode] = {
                              'name': name,
                              'price': price,
                              'offer': offer,
                              'quantity': '1'
                            };
                          }
                          barcode =
                              "No hay código escaneado."; // Reset barcode text
                        });
                        Navigator.of(context).pop();
                        scanBarcode(); // Vuelve a abrir el escáner
                      },
                      child: const Text("Agregar"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  double calculateTotal() {
    double total = 0.0;
    scannedProducts.forEach((barcode, productInfo) {
      total += calculateProductPrice(productInfo);
    });
    setState(() {
      priceProducts = total;
    });
    return total;
  }

  double calculateProductPrice(Map<String, String> productInfo) {
    double unitPrice = double.parse(productInfo['price']!.replaceAll('€', ''));
    int quantity = int.parse(productInfo['quantity']!);
    if (productInfo['offer'] == '1x1€') {
      return unitPrice * quantity; // Mostrar precio por unidad sin oferta
    } else {
      // Aplicar lógica de oferta
      if (productInfo['offer'] != 'N/A') {
        List<String> offerDetails = productInfo['offer']!.split('x');
        int offerQuantity = int.parse(offerDetails[0]);
        double offerPrice = double.parse(offerDetails[1].replaceAll('€', ''));
        int offerBundles = quantity ~/ offerQuantity;
        int remainingItems = quantity % offerQuantity;
        return (offerBundles * offerPrice) + (remainingItems * unitPrice);
      } else {
        return unitPrice * quantity; // Sin oferta
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Producto'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistroProductos(),
                ),
              );
            },
            icon: const Icon(Icons.app_registration),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: scanBarcode,
                  child: const Text('Escanear Código de Barras'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: scanBarcodeForRemoval,
                  child: const Text('Eliminar'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              barcode,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: scannedProducts.length,
                itemBuilder: (context, index) {
                  String barcode = scannedProducts.keys.elementAt(index);
                  Map<String, String> productInfo = scannedProducts[barcode]!;
                  double totalPricePerProduct =
                      calculateProductPrice(productInfo);

                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${productInfo['name']} (x${productInfo['quantity']})'),
                        Text(barcode, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    trailing: productInfo['quantity'] != '1'
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '(${productInfo['price']!}) ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              Text(
                                '= ${totalPricePerProduct.toStringAsFixed(2)}€',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            '${totalPricePerProduct.toStringAsFixed(2)}€',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: removeAllProducts,
                  child: const Text('Eliminar Todo'),
                ),
                Text(
                  'Total: ${calculateTotal().toStringAsFixed(2)}€',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
