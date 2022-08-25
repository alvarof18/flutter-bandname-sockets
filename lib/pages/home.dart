import 'dart:io';

import 'package:bandname_app/models/band.dart';
import 'package:bandname_app/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Band> bands = [
    // Band(name: 'Banda 1', id: '1', votes: 2),
    // Band(name: 'Banda 2', id: '2', votes: 0),
    // Band(name: 'Banda 3', id: '3', votes: 1),
    // Band(name: 'Banda 4', id: '4', votes: 5),
    // Band(name: 'Banda 5', id: '5', votes: 9),
  ];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('actives-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    //Para que se redibuje los widgets cada vez que se reciba un mensaje active-bands
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    //dejo de escuchar por ese evento luego de escuchar
    socketService.socket.off('actives-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 1,
        actions: [
          Container(
              margin: const EdgeInsets.only(right: 10),
              child: (socketService.serverStatus == ServerStatus.onLine)
                  ? Icon(
                      Icons.check_circle,
                      color: Colors.blue[300],
                    )
                  : const Icon(Icons.offline_bolt, color: Colors.red))
        ],
        title: const Text(
          'BandNames',
          style: TextStyle(color: Colors.black38),
        ),
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _showGrap(),
          Expanded(
              child: ListView.builder(
                  itemCount: bands.length,
                  itemBuilder: (_, int index) => _bandTile(bands[index])))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewBand,
        elevation: 1,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);
    return Dismissible(
      key: Key(band.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) {
        socketService.socket.emit('delete-band', {'id': band.id});
      },
      background: Container(
        padding: const EdgeInsets.only(left: 8.0),
        color: Colors.red,
        child: const Align(
          alignment: Alignment.centerLeft,
          child: Text('Delete Band', style: TextStyle(color: Colors.white)),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(band.name.substring(0, 2).toUpperCase()),
        ),
        title: Text(band.name),
        trailing: Text(
          band.votes.toString(),
          style: const TextStyle(fontSize: 20),
        ),
        onTap: () {
          socketService.socket.emit('voted-band', {'id': band.id});
        },
      ),
    );
  }

  addNewBand() {
    final textController = TextEditingController();

    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              title: const Text('New Band'),
              content: TextField(
                controller: textController,
              ),
              actions: [
                MaterialButton(
                    elevation: 5,
                    textColor: Colors.blue,
                    onPressed: () => addBandToList(textController.text),
                    child: const Text('Add'))
              ],
            );
          });
    }

    showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
              title: const Text('New Band'),
              content: CupertinoTextField(
                controller: textController,
              ),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Add'),
                  onPressed: () => addBandToList(textController.text),
                ),
                CupertinoDialogAction(
                  isDestructiveAction: true,
                  child: const Text('Dismiss'),
                  onPressed: () => Navigator.pop(context),
                )
              ]);
        });
  }

  void addBandToList(String nameBand) {
    if (nameBand.length > 1) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.socket.emit('add-band', {'name': nameBand});
    }
    Navigator.pop(context);
  }

  //Mostrar grafica

  Widget _showGrap() {
    Map<String, double> dataMap = Map();

    bands.forEach((band) {
      dataMap.putIfAbsent(band.name, () => band.votes.toDouble());
    });

    return Container(
      width: double.infinity,
      height: 200,
      child: PieChart(
        dataMap: dataMap,
        chartType: ChartType.disc,
      ),
    );
  }
}
