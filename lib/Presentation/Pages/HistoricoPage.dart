import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({super.key});

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  List<dynamic>? corridas; // Lista de corridas carregadas
  bool carregando = false; // Indicador de carregamento
  String? erro; // Guarda erro se acontecer

  @override
  void initState() {
    super.initState();
    carregarCorridas();
  }

  Future<void> carregarCorridas() async {
    if (!mounted) return;
    setState(() {
      carregando = true;
      erro = null;
      corridas = null; // <- Zera a lista para aparecer o loading sempre que clicar no atualizar
    });

    try {
      final response = await http.get(Uri.parse('http://192.168.0.41:5265/api/HistoricoCorridas/regiane%3ARMY9E31'));

      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          corridas = jsonDecode(response.body);
        });
      } else {
        if (!mounted) return;
        setState(() {
          erro = 'Erro ao carregar corridas (Código ${response.statusCode})';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        erro = 'Erro: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        carregando = false;
      });
    }
  }

  String formatarData(String data) {
    final dateTime = DateTime.parse(data);
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  void mostrarDetalhes(BuildContext context, Map<String, dynamic> corrida) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Center(
                child: Text(
                  'Detalhes da Corrida ${corrida['idCorrida']}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              _detalheItem('Velocidade Máxima', '${corrida['velocidadeMaxima']} km/h'),
              _detalheItem('Velocidade Mínima', '${corrida['velocidadeMinima']} km/h'),
              _detalheItem('Velocidade Média', '${corrida['velocidadeMedia'].toStringAsFixed(2)} km/h'),
              const Divider(),
              _detalheItem('RPM Máximo', '${corrida['rpmMaximo']}'),
              _detalheItem('RPM Mínimo', '${corrida['rpmMinimo']}'),
              _detalheItem('RPM Médio', '${corrida['rpmMedio'].toStringAsFixed(2)}'),
              const Divider(),
              _detalheItem('Data Início', formatarData(corrida['dataInicio'])),
              _detalheItem('Data Fim', formatarData(corrida['dataFim'])),
            ],
          ),
        );
      },
    );
  }

  Widget _detalheItem(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(valor, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              carregarCorridas();
            },
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (carregando && corridas == null) {
            return const Center(child: CircularProgressIndicator());
          } else if (erro != null) {
            return Center(child: Text(erro!));
          } else if (corridas == null || corridas!.isEmpty) {
            return const Center(child: Text('Nenhuma corrida encontrada.'));
          } else {
            return ListView.builder(
              itemCount: corridas!.length,
              itemBuilder: (context, index) {
                var corrida = corridas![index];
                return GestureDetector(
                  onTap: () => mostrarDetalhes(context, corrida),
                  child: Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Corrida ${corrida['idCorrida']}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text('Início: ${formatarData(corrida['dataInicio'])}'),
                          Text('Fim: ${formatarData(corrida['dataFim'])}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
