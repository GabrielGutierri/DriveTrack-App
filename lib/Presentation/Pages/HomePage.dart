import 'package:flutter/material.dart';
import 'package:drivetrack/IoC/DependencyFactory.dart';
import 'package:drivetrack/Presentation/Pages/BluetoothPage.dart';
import 'package:drivetrack/Presentation/Pages/HistoricoPage.dart';
import 'package:drivetrack/Presentation/Pages/SettingsPage.dart';

class HomePage extends StatefulWidget {
  
  const HomePage({super.key});
  
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<BluetoothPageState> bluetoothPageKey = GlobalKey<BluetoothPageState>();
  int _currentIndex = 0;
  late final BluetoothPage bluetoothPage;
  late final List<Widget> _pages;
  @override
  void initState() {
    super.initState();
    bluetoothPage = DependencyFactory.createBluetoothPage(key: bluetoothPageKey);
    _pages = [
    bluetoothPage,
    const HistoricoPage(),
    const SettingsPage(),
  ];
  }

  // Função para mudar de página
  void _onItemTapped(int index) {
    if(bluetoothPageKey.currentState?.comandosIniciados == true && index != 0){
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: IndexedStack(
      index: _currentIndex,
      children: _pages,
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: _onItemTapped,
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Bluetooth',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Histórico',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: 'Configurações',
        ),
      ],
    ),
  );
}

}