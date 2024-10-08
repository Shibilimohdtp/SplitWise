import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/models/group.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('splitwise.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        groupId TEXT,
        payerId TEXT,
        amount REAL,
        description TEXT,
        date INTEGER,
        splitDetails TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE groups (
        id TEXT PRIMARY KEY,
        name TEXT,
        description TEXT,
        creatorId TEXT,
        members TEXT
      )
    ''');
  }

  Future<String> insertExpense(Expense expense) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newExpense = expense.copyWith(id: id);
    await db.insert('expenses', newExpense.toMap());
    return id;
  }

  Future<void> insertGroup(Group group) async {
    final db = await database;
    await db.insert('groups', group.toMap());
  }

  Future<List<Expense>> getOfflineExpenses() async {
    final db = await database;
    final maps = await db.query('expenses');
    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  Future<List<Group>> getOfflineGroups() async {
    final db = await database;
    final maps = await db.query('groups');
    return List.generate(maps.length, (i) {
      return Group.fromMap(maps[i]);
    });
  }

  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteGroup(String id) async {
    final db = await database;
    await db.delete('groups', where: 'id = ?', whereArgs: [id]);
  }
}
