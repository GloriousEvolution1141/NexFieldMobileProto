import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('suministros_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE foto ADD COLUMN latitud TEXT');
        await db.execute('ALTER TABLE foto ADD COLUMN longitud TEXT');
        await db.execute('ALTER TABLE foto ADD COLUMN nota TEXT');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE foto ADD COLUMN nombre TEXT');
        await db.execute('ALTER TABLE foto RENAME COLUMN fecha_hora TO created_at');
      } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';

    await db.execute('''
CREATE TABLE suministro (
  id $idType,
  nombre $textNullable,
  estado $textType,
  asignado_a $textType
)
''');

    await db.execute('''
CREATE TABLE foto (
  id $idType,
  suministro_id $textType,
  nombre $textNullable,
  direccion $textType,
  creado_por $textNullable,
  created_at $textNullable,
  latitud $textNullable,
  longitud $textNullable,
  nota $textNullable
)
''');

    await db.execute('''
CREATE TABLE cola_tareas (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo_accion $textType,
  tabla $textType,
  datos_json $textType,
  ruta_archivo_local $textNullable,
  fecha_creacion $textType
)
''');
  }

  Future<void> syncSuministros(List<dynamic> suministros, String userId) async {
    final db = await instance.database;
    
    final suministrosLocales = await db.query('suministro', where: 'asignado_a = ?', whereArgs: [userId]);
    final Set<String> idsNube = suministros.map((s) => s['id'].toString()).toSet();
    
    final suministrosAEliminar = suministrosLocales.where((s) => !idsNube.contains(s['id'].toString())).toList();
    
    for (var s in suministrosAEliminar) {
      final String suId = s['id'].toString();
      final fotosDelSuministro = await getFotosBySuministro(suId);
      
      for (var f in fotosDelSuministro) {
        final String? rutaLocal = f['direccion'];
        if (rutaLocal != null && !rutaLocal.startsWith('http')) {
          try {
            final file = File(rutaLocal);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
        }
      }
      await db.delete('foto', where: 'suministro_id = ?', whereArgs: [suId]);
    }

    Batch batch = db.batch();
    batch.delete('suministro', where: 'asignado_a = ?', whereArgs: [userId]);
    
    for (var s in suministros) {
      batch.insert('suministro', {
        'id': s['id'].toString(),
        'nombre': s['nombre'],
        'estado': s['estado'],
        'asignado_a': userId, 
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getSuministros(String userId) async {
    final db = await instance.database;
    return await db.query(
      'suministro',
      where: 'asignado_a = ?',
      whereArgs: [userId],
    );
  }

  Future<void> actualizarEstadoSuministroLocal(String id, String estado) async {
    final db = await instance.database;
    await db.update(
      'suministro',
      {'estado': estado},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> syncFotos(String suministroId, List<dynamic> fotos) async {
    final db = await instance.database;
    Batch batch = db.batch();
    
    batch.delete('foto', where: 'suministro_id = ? AND (direccion LIKE "http%" OR direccion LIKE "https%")', whereArgs: [suministroId]);
    
    for (var f in fotos) {
      batch.insert('foto', {
        'id': f['id'].toString(),
        'suministro_id': suministroId,
        'nombre': f['nombre'] ?? 'Foto',
        'direccion': f['direccion'] ?? '',
        'creado_por': f['creado_por'],
        'created_at': f['created_at'],
        'latitud': f['latitud'],
        'longitud': f['longitud'],
        'nota': f['nota'],
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getFotosBySuministro(String suministroId) async {
    final db = await instance.database;
    return await db.query(
      'foto',
      where: 'suministro_id = ?',
      whereArgs: [suministroId],
    );
  }
  
  Future<void> insertFotoLocal(Map<String, dynamic> fotoMap) async {
    final db = await instance.database;
    await db.insert('foto', fotoMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> eliminarFotoLocal(String id) async {
    final db = await instance.database;
    await db.delete('foto', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> encolarTarea(String tipoAccion, String tabla, Map<String, dynamic> datos, {String? rutaArchivoLocal}) async {
    final db = await instance.database;
    await db.insert('cola_tareas', {
      'tipo_accion': tipoAccion,
      'tabla': tabla,
      'datos_json': jsonEncode(datos),
      'ruta_archivo_local': rutaArchivoLocal,
      'fecha_creacion': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getTareasPendientes() async {
    final db = await instance.database;
    return await db.query('cola_tareas', orderBy: 'id ASC');
  }

  Future<void> eliminarTarea(int id) async {
    final db = await instance.database;
    await db.delete('cola_tareas', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
