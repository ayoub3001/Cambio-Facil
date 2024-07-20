import 'package:cambio_facil/main.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../Domain/Data/variables.dart';

class CodeInputScreen extends StatefulWidget {
  const CodeInputScreen({super.key});

  @override
  CodeInputScreenState createState() => CodeInputScreenState();
}

class CodeInputScreenState extends State<CodeInputScreen> {
  String code = '';

  void _addNumber(int number) {
    setState(() {
      if (code.length < 4) {
        code += number.toString();
      }
    });
  }

  void _removeLastNumber() {
    if (code.isNotEmpty) {
      setState(() {
        code = code.substring(0, code.length - 1);
      });
    }
  }

  void _confirmCode() {
    if (listaBasesDeDatos.contains(code)) {
      Hive.box("myBox").put("isFirstTime", false);

      Hive.box("myBox").put("codeDB", code);
      codeDB = code;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const MainPage(isFirstTime: false)));
    } else {
      setState(() {
        code = "";
      });
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                title: const Text('Error'),
                content: const Text('La base de datos no existe.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar el diálogo
                    },
                  )
                ]);
          });
    }
  }

  Widget _buildButton(String label, VoidCallback onPressed,
      {bool isSpecial = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: MaterialButton(
          onPressed: onPressed,
          height: 80,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
          color: isSpecial ? Colors.indigo[700] : Colors.grey[200],
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isSpecial ? Colors.white : Colors.indigo[700],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                children: [
                  Text(
                    'Introduce tu código',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800]),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      code.padRight(4, '_'),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                        letterSpacing: 24,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Row(
                        children: [
                          for (var j = 1; j <= 3; j++)
                            _buildButton(
                              '${i * 3 + j}',
                              () => _addNumber(i * 3 + j),
                            ),
                        ],
                      ),
                    Row(
                      children: [
                        _buildButton('Borrar', _removeLastNumber,
                            isSpecial: true),
                        _buildButton('0', () => _addNumber(0)),
                        _buildButton('Confirmar', _confirmCode,
                            isSpecial: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
