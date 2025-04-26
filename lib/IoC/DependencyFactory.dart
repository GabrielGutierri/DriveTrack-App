import 'package:flutter/material.dart';
import 'package:drivetrack/Business/Controllers/BluetoothController.dart';
import 'package:drivetrack/Business/Controllers/IdentificacaoCarroController.dart';
import 'package:drivetrack/Business/Services/FiwareService.dart';
import 'package:drivetrack/Business/Services/OBDService.dart';
import 'package:drivetrack/Business/Services/RequestFIWAREService.dart';
import 'package:drivetrack/Presentation/Pages/BluetoothPage.dart';
import 'package:drivetrack/Presentation/Pages/IdentificacaoCarroPage.dart';

class DependencyFactory {
  static BluetoothPage createBluetoothPage({Key? key}) {
    final obdService = Obdservice();
    final bluetoothController = BluetoothController(obdService);
    return BluetoothPage(bluetoothController, key);
  }

  static IdentificacaoCarroPage createIdentificacaoCarroPage() {
    final fiwareservice = Fiwareservice();
    final requestService = RequestFIWAREService();
    final identificacaoCarroController =
        IdentificacaoCarroController(fiwareservice, requestService);
    return IdentificacaoCarroPage(identificacaoCarroController);
  }
}
