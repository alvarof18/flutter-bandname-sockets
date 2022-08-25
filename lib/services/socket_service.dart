import 'package:flutter/material.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

enum ServerStatus { onLine, offLine, Conecting }

class SocketService with ChangeNotifier {
  ServerStatus _serverStatus = ServerStatus.Conecting;
  late IO.Socket _socket;

  SocketService() {
    initConfig();
  }

  ServerStatus get serverStatus => _serverStatus;
  IO.Socket get socket => _socket;

  void initConfig() {
    _socket = IO.io(
        'http://192.168.56.1:3000/',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .build());

    // Conectado al Server
    _socket.onConnect((_) {
      _serverStatus = ServerStatus.onLine;
      notifyListeners();
      //print('connect');
    });
    // Desconectado del server
    _socket.onDisconnect((_) {
      _serverStatus = ServerStatus.offLine;
      notifyListeners();
    });

    // socket.on('nuevo-mensaje', (data) {
    //   print('Nombre: ' + data['nombre']);
    //   print('Mensaje: ' + data['mensaje']);
    // });
    // // socket.on('fromServer', (_) => print(_));
  }
}
