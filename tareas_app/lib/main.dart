import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(MaterialApp(home: TareasApp()));
}

class TareasApp extends StatefulWidget {
  @override
  _TareasAppState createState() => _TareasAppState();
}

class _TareasAppState extends State<TareasApp> {
  Database? db;
  List<Map<String, dynamic>> tareas = [];
  final TextEditingController controller = TextEditingController();

  int? tareaEditandoId;
  String mensaje = '';

  @override
  void initState() {
    super.initState();
    initDb();
  }

  Future<void> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'tareas.db');
    db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tareas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            titulo TEXT NOT NULL
          )
        ''');
      },
    );
    await cargarTareas();
  }

  Future<void> cargarTareas() async {
    if (db == null) return;
    final data = await db!.query('tareas');
    setState(() {
      tareas = data;
    });
  }

  Future<void> guardarTarea() async {
    if (controller.text.isEmpty || db == null) return;
    if (tareaEditandoId == null) {
      await db!.insert('tareas', {'titulo': controller.text.trim()});
    } else {
      await db!.update(
        'tareas',
        {'titulo': controller.text.trim()},
        where: 'id = ?',
        whereArgs: [tareaEditandoId],
      );
      tareaEditandoId = null;
    }
    controller.clear();
    mensaje = '';
    await cargarTareas();
  }

  void prepararEdicion(int id, String titulo) {
    setState(() {
      controller.text = titulo;
      tareaEditandoId = id;
      mensaje = 'Editando tarea ID $id';
    });
  }

  Future<void> eliminarTarea(int id) async {
    if (db == null) return;
    await db!.delete('tareas', where: 'id = ?', whereArgs: [id]);
    await cargarTareas();
    setState(() {
      if (tareaEditandoId == id) {
        tareaEditandoId = null;
        controller.clear();
      }
    });
  }

  Future<void> exportarTxt() async {
    if (db == null) return;
    final data = await db!.query('tareas');
    String contenido = "ID | Tarea\n";
    for (var tarea in data) {
      contenido += "${tarea['id']} | ${tarea['titulo']}\n";
    }

    var permiso = await Permission.manageExternalStorage.request();
    if (permiso.isGranted) {
      final dir = await getExternalStorageDirectory();
      final path = '${dir!.path}/tareas_exportadas.txt';
      final file = File(path);
      await file.writeAsString(contenido);
      setState(() {
        mensaje = 'Archivo exportado en:\n$path';
      });
      print(mensaje);
    } else {
      setState(() {
        mensaje = 'Permiso denegado para almacenamiento externo';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Guardar en BD SQLite')),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(hintText: 'Escribe la tarea'),
              onSubmitted: (_) => guardarTarea(),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: guardarTarea,
                  child: Text(tareaEditandoId == null ? 'Agregar' : 'Guardar cambios'),
                ),
                ElevatedButton(
                  onPressed: exportarTxt,
                  child: Text('Exportar a .txt'),
                ),
              ],
            ),
            if (mensaje.isNotEmpty) ...[
              SizedBox(height: 10),
              Text(
                mensaje,
                style: TextStyle(color: Colors.green),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 10),
            Expanded(
              child: tareas.isEmpty
                  ? Center(child: Text('No hay tareas.'))
                  : ListView.builder(
                      itemCount: tareas.length,
                      itemBuilder: (_, i) => ListTile(
                        title: Text(tareas[i]['titulo']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => prepararEdicion(
                                tareas[i]['id'],
                                tareas[i]['titulo'],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => eliminarTarea(tareas[i]['id']),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
