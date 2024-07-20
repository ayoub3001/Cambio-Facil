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
  ).ref().child(codeDB).child("Productos");

  Map<String, Map<String, String>> existingProducts = {};

  String barcode = "No hay código escaneado.";

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

    // Si no existe la key 'offer' o su valor es 'N/A', simplemente multiplicamos el precio unitario por la cantidad
    if (!productInfo.containsKey('offer') || productInfo['offer'] == 'N/A') {
      return unitPrice * quantity;
    }

    // Si hay una oferta, la aplicamos
    List<String> offerDetails = productInfo['offer']!.split('x');
    int offerQuantity = int.parse(offerDetails[0]);
    double offerPrice = double.parse(offerDetails[1].replaceAll('€', ''));

    int offerBundles = quantity ~/ offerQuantity;
    int remainingItems = quantity % offerQuantity;

    return (offerBundles * offerPrice) + (remainingItems * unitPrice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(
                top: 20,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ESCANEAR PRODUCTO",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    color: Colors.purple,
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistroProductos(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.app_registration,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1.0,
              width: MediaQuery.of(context).size.width,
              color: Colors.purple,
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    child: GestureDetector(
                  onTap: scanBarcode,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Text(
                        'Escanear Código de Barras',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      )),
                )),
                const SizedBox(
                  width: 20,
                ),
                Expanded(
                  child: GestureDetector(
                      onTap: scanBarcodeForRemoval,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text('Eliminar producto',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center),
                      )),
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
                GestureDetector(
                  onTap: removeAllProducts,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.red),
                    child: const Text(
                      'Eliminar Todo',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
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
