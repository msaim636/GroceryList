import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(Object context) {
    return MaterialApp(home: ShoppingList(), debugShowCheckedModeBanner: false);
  }
}

class ShoppingList extends StatefulWidget {
  const ShoppingList({super.key});

  @override
  State<ShoppingList> createState() => _ShoppingListState();
}

class groceryItem {
  int? id;
  late String name;
  late int quantity;

  groceryItem({required this.id, required this.name, required this.quantity});
}

class _ShoppingListState extends State<ShoppingList> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _quantity = TextEditingController();
  List<groceryItem> list = [];
  int itemCount = 0;

  //load items from database when ap restarts
  Future<void> loadItems() async {
    final data = await DatabaseHelper.instance.readRecord();

    setState(() {
      list = data.map((row) {
        return groceryItem(
          name: row[DatabaseHelper.ItemName],
          quantity: row[DatabaseHelper.ItemQuantity],
          id: row[DatabaseHelper.ItemId],
        );
      }).toList();

      itemCount = list.length;
    });
  }

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Grocery List',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Colors.green.shade300,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _name,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Item Name',
                suffixIcon: Icon(Icons.shopping_bag),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              keyboardType: TextInputType.numberWithOptions(),
              controller: _quantity,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Item Quantity',
                suffixIcon: Icon(Icons.numbers_rounded),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade300,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.white),
                  Text('Add', style: TextStyle(color: Colors.white)),
                ],
              ),
              onPressed: () async {
                final name = _name.text.trim();
                final qty = int.tryParse(_quantity.text.trim());

                if (name.isEmpty || qty == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid name and quantity'),
                    ),
                  );
                  return;
                }

                await DatabaseHelper.instance.insertRecord({
                  DatabaseHelper.ItemName: name,
                  DatabaseHelper.ItemQuantity: qty,
                });
                var Read = await DatabaseHelper.instance.readRecord();
                print(Read);

                _name.clear();
                _quantity.clear();
                await loadItems();
              },
            ),
          ),

          ListTile(
            title: Text(
              'My Items',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Container(
              height: 25,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  '$itemCount Items',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade400,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];

                return Card(
                  color: Colors.white,
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: ListTile(
                    title: Text(
                      item.name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Quantity: ${item.quantity}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final editName = TextEditingController(
                              text: item.name,
                            );
                            final editQuantity = TextEditingController(
                              text: item.quantity.toString(),
                            );
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Edit Item'),
                                  content: Column(
                                    children: [
                                      TextField(
                                        controller: editName,
                                        decoration: InputDecoration(
                                          label: Text('Item Name'),
                                        ),
                                      ),
                                      TextField(
                                        controller: editQuantity,
                                        decoration: InputDecoration(
                                          label: Text('Quantity'),
                                        ),
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () async {
                                              final name = editName.text.trim();
                                              final quantity = editQuantity.text
                                                  .trim();
                                              final id = item.id;
                                              await DatabaseHelper.instance
                                                  .updateRecord({
                                                    DatabaseHelper.ItemId: id,
                                                    DatabaseHelper.ItemName:
                                                        name,
                                                    DatabaseHelper.ItemQuantity:
                                                        quantity,
                                                  });
                                              var Read = await DatabaseHelper
                                                  .instance
                                                  .readRecord();
                                              print(Read);
                                              await loadItems();
                                              Navigator.pop(context);
                                            },
                                            child: Text('Save Changes'),
                                          ),
                                          SizedBox(width: 7),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: Text('Cancle'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          icon: Icon(Icons.edit),
                          color: Colors.green.shade300,
                        ),
                        IconButton(
                          onPressed: () async {
                            await DatabaseHelper.instance.deleteRecord(
                              item.id!,
                            );
                            await loadItems();
                          },
                          icon: Icon(Icons.delete),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DatabaseHelper {
  static const dbName = "myDatabase.db";
  static const dbVersion = 1;
  static const dbTable = "myTable";
  static const ItemId = 'id';
  static const ItemName = 'name';
  static const ItemQuantity = 'quantity';
  //constructor
  static final DatabaseHelper instance = DatabaseHelper();

  //database initialize
  static Database? _database;
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDB();
    return _database!;
  }

  initDB() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = join(directory.path, dbName);
    return await openDatabase(path, version: dbVersion, onCreate: onCreate);
  }

  Future onCreate(Database db, int version) async {
    db.execute('''

CREATE TABLE $dbTable(
$ItemId INTEGER PRIMARY KEY AUTOINCREMENT, $ItemName TEXT NOT NULL, $ItemQuantity INTEGER
)


''');
  }

  insertRecord(Map<String, dynamic> row) async {
    Database? db = await instance.database;
    return await db!.insert(dbTable, row);
  }

  Future<List<Map<String, dynamic>>> readRecord() async {
    Database? db = await instance.database;
    return await db!.query(dbTable);
  }

  Future<int> updateRecord(Map<String, dynamic> row) async {
    Database? db = await instance.database;
    int id = row[ItemId];
    return await db!.update(dbTable, row, where: '$ItemId=?', whereArgs: [id]);
  }

  Future<int> deleteRecord(int id) async {
    Database? db = await instance.database;
    return await db!.delete(dbTable, where: '$ItemId=?', whereArgs: [id]);
  }
}
