import 'dart:async';
import 'package:flutter_sensors/flutter_sensors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:drivetrack/Business/Services/OBDService.dart';
import 'package:drivetrack/Domain/entities/Acelerometro.dart';
import 'package:drivetrack/Domain/entities/Giroscopio.dart';

class GeolocationService {
  double _aceleracaoX = 0.0;
  double _aceleracaoY = 0.0; // Aceleração longitudinal
  double _aceleracaoZ = 0.0;

  double _giroscopioX = 0.0;
  double _giroscopioY = 0.0;
  double _giroscopioZ = 0.0;

  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;

  GeolocationService() {
    // Inicializar os sensores
    // _initializeSensors();
  }

  // Método para inicializar e escutar os eventos do acelerômetro e giroscópio
  Future<void> initializeSensors() async {
    bool hasAccel =
        await SensorManager().isSensorAvailable(Sensors.ACCELEROMETER);
    bool hasGyro = await SensorManager().isSensorAvailable(Sensors.GYROSCOPE);

    if (hasAccel) {
      final accelerometerStream = await SensorManager().sensorUpdates(
        sensorId: Sensors.ACCELEROMETER,
        interval: const Duration(milliseconds: 100),
      );

      _accelerometerSubscription = accelerometerStream.listen((event) {
        final data = event.data;
        _aceleracaoX = data[0];
        _aceleracaoY =
            data[1]; // Assumindo o eixo Y como aceleração longitudinal
        _aceleracaoZ = data[2];
      });
    }

    if (hasGyro) {
      final gyroscopeStream = await SensorManager().sensorUpdates(
        sensorId: Sensors.GYROSCOPE,
        interval: const Duration(milliseconds: 100),
      );

      _gyroscopeSubscription = gyroscopeStream.listen((event) {
        final data = event.data;
        _giroscopioX = data[0];
        _giroscopioY = data[1];
        _giroscopioZ = data[2];
      });
    }
  }

  Future<Position> obterGeolocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true);
    return position;
  }

  //obter apenas a aceleracaoX, aceleracaoY e aceleracaoZ... realizar calculos depois no pós processamento
  Future<Acelerometro> obterAcelerometro() async {
    //obter acelerometro e giroscopio?
    Acelerometro dadoAcelerometro = Acelerometro(
        aceleracaoX: _aceleracaoX,
        aceleracaoY: _aceleracaoY,
        aceleracaoZ: _aceleracaoZ);
    return dadoAcelerometro;
  }

  // Método para obter o valor do giroscópio
  Future<Giroscopio> obterGiroscopio() async {
    return new Giroscopio(
        giroscopioX: _giroscopioX,
        giroscopioY: _giroscopioY,
        giroscopioZ: _giroscopioZ);
  }

  Future getDadosGeolocalizacao() async {
    Position geolocation = await obterGeolocation();

    Acelerometro acelerometro = await obterAcelerometro();

    Giroscopio giroscopio = await obterGiroscopio();

    Obdservice.latitude = geolocation.latitude;
    Obdservice.longitude = geolocation.longitude;
    Obdservice.aceleracaoX = acelerometro.aceleracaoX;
    Obdservice.aceleracaoY = acelerometro.aceleracaoY;
    Obdservice.aceleracaoZ = acelerometro.aceleracaoZ;
    Obdservice.giroscopioX = giroscopio.giroscopioX;
    Obdservice.giroscopioY = giroscopio.giroscopioY;
    Obdservice.giroscopioZ = giroscopio.giroscopioZ;
  }
}
