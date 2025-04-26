import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drivetrack/Business/Controllers/BluetoothController.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:drivetrack/Business/Services/NativeService.dart';
import 'package:drivetrack/Business/Services/OBDService.dart';
import 'package:drivetrack/Business/Utils/MetodosUtils.dart';
import 'package:drivetrack/Business/Utils/TrataMensagemOBD.dart';

class BluetoothPage extends StatefulWidget {
  final BluetoothController _bluetoothController;

  BluetoothPage(this._bluetoothController, Key? key): super(key: key);

  @override
  BluetoothPageState createState() => BluetoothPageState();
}

class BluetoothPageState extends State<BluetoothPage> {
  static const platform = const MethodChannel('foregroundOBD_service');
  String _serverState = 'Did not make the call yet';
  bool bluetoothValido = false;
  bool comandosIniciados = false;
  bool get corridaAtiva => comandosIniciados;
  bool bluetoothVerificado = false;
  final TextEditingController _comandoOBDController = TextEditingController();
  Timer? timerInfosOBD;
  Timer? timer;
  bool? statusConexaoELM;
  bool? statusForeground;
  String velocidade = "0";
  String rpm = "0";
  String temperatura = "0";
  String pressao = "0";
  String engineLoad = "0";
  String throttle = "0";

  Future<void> _startService() async {
    try {
      final result = await platform.invokeMethod('startForegroundService');
      setState(() {
        _serverState = result;
      });
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }

  Future PararServicoFIWARE(BuildContext context, bool envioFIWARE) async {
    if (envioFIWARE) {
      await Future.delayed(Duration(seconds: 1));
      showDialog(
        context: context,
        barrierDismissible: false, // Evita fechar ao clicar fora
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black87, // Cor do fundo do diálogo
            elevation: 8, // Elevação do diálogo
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Bordas arredondadas
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16), // Espaço entre o spinner e o texto
                Text(
                  'Sincronizando dados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      );
      try {
        await NativeService.stopServices(envioFIWARE: true);
      } finally {
        Navigator.of(context).pop();
      }
    } else {
      await NativeService.stopServices(envioFIWARE: false);
      _exibirMensagemErro(context,
          "Não foi possível sincronizar os dados com o FIWARE... o aplicativo tentará novamente quando você entrar de novo!");
    }
  }

  Future<void> _stopService(BuildContext context) async {
    try {
      final result = await platform.invokeMethod('stopForegroundService');
      NativeService.foreGroundParou = true;
      bool conexaoComInternet = await Metodosutils.VerificaConexaoInternet();
      if (conexaoComInternet) {
        await PararServicoFIWARE(context, true);
      } else {
        await PararServicoFIWARE(context, false);
      }
      setState(() {
        _serverState = result;
      });
    } on PlatformException catch (e) {
      print("Failed to invoke method: '${e.message}'.");
    }
  }

  String _montaTextoDispositivo(Device dispositivo) {
    if (dispositivo.name!.isEmpty) {
      return "Dispositivo Desconhecido";
    }
    return dispositivo.name!;
  }

  Future<void> _rotinaConexaoBluetooth(
      Device dispositivo, BuildContext context) async {
    try {
       bool conectado =
           await widget._bluetoothController.ConectarAoDispositivo(dispositivo);
      //bool conectado = true;
      if (!conectado) {
        _exibirMensagemErro(
            context, 'Erro ao conectar ao dispositivo Bluetooth.');
      } else {
        // Quando a conexão for bem-sucedida, atualizar o estado da página
         await widget._bluetoothController.salvarUltimoDispositivo(dispositivo.address);
        setState(() {
          bluetoothValido = true;
          comandosIniciados = false;
        });
        Navigator.of(context).pop(); // Fecha o modal após a conexão

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Sucesso'),
              content: Text("Dispositivo conectado com sucesso!"),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      _exibirMensagemErro(
          context, 'Erro ao conectar ao dispositivo Bluetooth.');
    }
  }



  Future<void> _rotinaConexaoBluetoothDispositivoEncontrado(
      Device dispositivo, BuildContext context) async {
    try {
      bool conectado =
          await widget._bluetoothController.ConectarAoDispositivo(dispositivo);
      //bool conectado = true;
      if (!conectado) {
        _exibirMensagemErro(
            context, 'Erro ao conectar ao dispositivo Bluetooth.');
      } else {
        // Quando a conexão for bem-sucedida, atualizar o estado da página
        await widget._bluetoothController.salvarUltimoDispositivo(dispositivo.address);

        setState(() {
          bluetoothValido = true;
          comandosIniciados = false;
        });
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Sucesso'),
              content: Text("Dispositivo conectado com sucesso!"),
              actions: [
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      _exibirMensagemErro(
          context, 'Erro ao conectar ao dispositivo Bluetooth.');
    }
  }


  void _exibirMensagemErro(BuildContext context, String mensagem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erro'),
          content: Text(mensagem),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> IniciarRotinaComandos(BuildContext context) async {
    try {
      bool bluetoothLigado =
          await widget._bluetoothController.VerificarBluetoothLigado();
      if (!bluetoothLigado) {
        _exibirMensagemErro(context, 'Atenção! Bluetooth não está ligado!');
        return;
      }

       await Future.delayed(Duration(seconds: 1));
       showDialog(
         context: context,
         barrierDismissible: false, // Evita fechar ao clicar fora
         builder: (BuildContext context) {
           return AlertDialog(
             backgroundColor: Colors.black87, // Cor do fundo do diálogo
             elevation: 8, // Elevação do diálogo
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.circular(8.0), // Bordas arredondadas
             ),
             content: Column(
               mainAxisSize: MainAxisSize.min,
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 CircularProgressIndicator(),
                 SizedBox(height: 16), // Espaço entre o spinner e o texto
                 Text(
                   'Verificando dispositivo OBD',
                   style: TextStyle(
                     fontSize: 16,
                     color: Colors.white,
                   ),
                 ),
               ],
             ),
           );
         },
       );
       bool obdOK = false;
       try {
         obdOK = await widget._bluetoothController.VerificarConexaoOBD();
       } finally {
         Navigator.of(context).pop();
       }
       if (!obdOK) {
         _exibirMensagemErro(context,
             "Atenção! OBD não está respondendo, verifique ele ou tente novamente!");
         return;
       }
       await widget._bluetoothController.rotinaComandos();
       await _startService();
      setState(() {
        bluetoothValido = true;
        comandosIniciados = true;
      });

       timer = Timer.periodic(Duration(seconds: 5), (_) {
         _checkStatus();
       });
      timerInfosOBD = Timer.periodic(Duration(seconds: 1), (_){
        _updateOBD();
      });
    } catch (e) {
      _exibirMensagemErro(context, 'Erro desconhecido ao iniciar a corrida');
    }
  }

  Future<void> PararRotinaComandos(BuildContext context) async {
    try {
      await NativeService.stopServices();
      await _stopService(context);
      setState(() {
        comandosIniciados = false;
        velocidade = "0";
        rpm = "0";
        temperatura = "0";
        pressao = "0";
        engineLoad = "0";
        throttle = "0";
      });
      timer?.cancel();
      timerInfosOBD?.cancel();
      
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Sucesso'),
            content: Text("Corrida encerrada com sucesso!"),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (ex) {
      _exibirMensagemErro(context, 'Erro desconhecido ao encerrar a corrida');
    }
  }

  void _checkStatus() async {
    bool conexaoELM =
        (NativeService.bluetoothConnection == null) ? false : true;
    bool foregroundRodando =
        (NativeService.foreGroundParou == true) ? false : true;
    // bool conexaoELM = true;
    // bool foregroundRodando = true;
    setState(() {
      statusConexaoELM = conexaoELM;
      statusForeground = foregroundRodando;
    });
  }

  void _updateOBD() async {
      String velocidadeTratada = TrataMensagemOBD.TrataMensagemVelocidade(Obdservice.velocidade);
      String rpmTratado = TrataMensagemOBD.TrataMensagemRPM(Obdservice.rpm);
      String temperaturaTratada = TrataMensagemOBD.TrataMensagemIntakeTemperature(Obdservice.temperatura);
      String pressaoTratada = TrataMensagemOBD.TrataMensagemIntakePressure(Obdservice.pressao);
      String engineLoadTratado = TrataMensagemOBD.TrataMensagemEngineLoad(Obdservice.engineLoad);
      String throttleTratado = TrataMensagemOBD.TrataMensagemThrottlePosition(Obdservice.throttle);
    setState(() {
      velocidade = (velocidadeTratada.contains('Erro'))? "-999": velocidadeTratada;
      rpm = (rpmTratado.contains('Erro'))? "-999" : double.parse(rpmTratado).toStringAsFixed(2); 
      temperatura = (temperaturaTratada.contains('Erro'))? "-999" : temperaturaTratada;
      pressao = (pressaoTratada.contains('Erro'))? "-999" : pressaoTratada;
      engineLoad = (engineLoadTratado.contains('Erro'))? "-999" : double.parse(engineLoadTratado).toStringAsFixed(2); 
      throttle = (throttleTratado.contains('Erro'))? "-999" : double.parse(throttleTratado).toStringAsFixed(2);
    });
  }

  Future<void> exibirModalDispositivos(BuildContext context) async {
    List<Device> dispositivosBluetooth =
        await widget._bluetoothController.ObterDispositivosPareados();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecione um dispositivo Bluetooth'),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: dispositivosBluetooth.length,
              itemBuilder: (context, index) {
                Device dispositivo = dispositivosBluetooth[index];
                return ListTile(
                  title: Text(_montaTextoDispositivo(dispositivo),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      await _rotinaConexaoBluetooth(dispositivo, context);
                    },
                    child: Text("Conectar", textAlign: TextAlign.center),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _verificarUltimoDispositivo() async {
    List<Device> dispositivos = await widget._bluetoothController.ObterDispositivosPareados();
    String? ultimoDispositivo = await widget._bluetoothController.obterUltimoDispositivo();
    bluetoothVerificado = true;

    if (ultimoDispositivo != null) {
      Device? dispositivoEncontrado = dispositivos.firstWhere(
        (device) => device.address == ultimoDispositivo,
        orElse: () => null as Device, // Cast para evitar erro
      );
      if (dispositivoEncontrado != null) {
        await _rotinaConexaoBluetoothDispositivoEncontrado(dispositivoEncontrado, context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _inicializarBluetooth();
  }

  void _inicializarBluetooth() async {
    if (!bluetoothVerificado) {
      await _verificarUltimoDispositivo();
      setState(() {}); // Atualiza a UI após a verificação
    }
  }

@override
Widget build(BuildContext context) {
  return PopScope(
    canPop: !comandosIniciados,
    onPopInvoked: (didPop) {
      if (!didPop && comandosIniciados) {
        _exibirMensagemErro(
          context,
          "Encerre a corrida antes de sair da tela!",
        );
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Conexão Bluetooth'),
        automaticallyImplyLeading: false,
      ),
      body: bluetoothVerificado
          ? _buildMainContent()
          : Center(child: CircularProgressIndicator()),
    ),
  );
}

  Widget _buildMainContent() {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (!bluetoothValido)
                  ElevatedButton(
                    onPressed: () {
                      exibirModalDispositivos(context);
                    },
                    child: const Text('Conectar'),
                  )
                else if (bluetoothValido && !comandosIniciados) ...[
                  ElevatedButton(
                    onPressed: () async {
                      await IniciarRotinaComandos(context);
                    },
                    child: const Text('Iniciar Corrida'),
                  )
                ] else if (bluetoothValido && comandosIniciados) ...[
                  _buildDashboard(),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      await PararRotinaComandos(context);
                    },
                    child: const Text('Encerrar corrida'),
                  )
                ],
              ],
            ),
          ),
        ),
        if (statusConexaoELM != null && statusForeground != null) ...[
          if (bluetoothValido && comandosIniciados) ...[
            if (statusConexaoELM == false) ...[
              _buildStatusBar("Dispositivo OBD desconectado", Colors.red)
            ],
            if (statusForeground == false) ...[
              _buildStatusBar("Serviço em segundo plano parou", Colors.red)
            ],
            if (statusConexaoELM == true && statusForeground == true) ...[
              _buildStatusBar("OBD e Serviço em segundo plano rodando", Colors.green)
            ]
          ]
        ]
      ],
    );
  }

  Widget _buildStatusBar(String text, Color bgColor) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: bgColor,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Text(
          text,
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildAro(String centerText, String label, Color color) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 4),
        ),
        alignment: Alignment.center,
        child: Text(
          centerText,
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
      SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

  Widget _buildDashboard() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(height: 20),
      _buildAroRow([
        _buildAro(velocidade.toString(), "Velocidade", Colors.red),
        _buildAro(rpm.toString(), "RPM", Colors.blue),
      ]),
      _buildAroRow([
        _buildAro(temperatura.toString(), "Temperatura", Colors.amber),
        _buildAro(pressao.toString(), "Pressão", Colors.orange),
      ]),
      _buildAroRow([
        _buildAro(engineLoad.toString(), "Engine Load", Colors.grey),
        _buildAro(throttle.toString(), "Throttle Position", Colors.green),
      ]),
    ],
  );
}

Widget _buildAroRow(List<Widget> aros) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: aros,
    ),
  );
}
}