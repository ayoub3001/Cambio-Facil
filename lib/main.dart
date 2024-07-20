import 'package:cambio_facil/UI/screens/code_input_screen.dart';
import 'package:cambio_facil/UI/screens/pageEscaner.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock/wakelock.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Domain/Data/variables.dart';
import 'UI/screens/my_home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final DatabaseReference dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL:
        'https://carniceria-amin-default-rtdb.europe-west1.firebasedatabase.app',
  ).ref();
  listarHijos(dbref: dbRef);

  await Hive.initFlutter();
  var box = await Hive.openBox('myBox');
  bool isFirstTime = box.get('isFirstTime') ?? true;
  codeDB = box.get('codeDB') ?? "";

  Wakelock.enable(); // Mantener la pantalla encendida
  runApp(MyApp(
    isFirstTime: isFirstTime,
  ));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculadora de Cambio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(isFirstTime: isFirstTime),
    );
  }
}

class MainPage extends StatefulWidget {
  final bool isFirstTime;
  const MainPage({super.key, required this.isFirstTime});

  @override
  MainPageState createState() => MainPageState();
}

class MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    MyHomePage(),
    PageEscaner(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFirstTime == true || codeDB == "") {
      return const Scaffold(
        body: CodeInputScreen(),
      );
    } else {
      if (codeDB == "8245") {
        return Scaffold(
          body: _pages[_selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.barcode_reader),
                label: 'Second',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Colors.purple,
            onTap: _onItemTapped,
          ),
        );
      } else {
        return const PageEscaner();
      }
    }
  }
}

Future<void> listarHijos({required DatabaseReference dbref}) async {
  try {
    DataSnapshot snapshot = await dbref.get();

    if (snapshot.exists) {
      listaBasesDeDatos = [];
      for (var child in snapshot.children) {
        listaBasesDeDatos.add(child.key);
      }
    }
    // ignore: empty_catches
  } catch (e) {}
}
