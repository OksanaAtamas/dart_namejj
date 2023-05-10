import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqlite3/sqlite3.dart';
import 'dart:io';

class Root {
  final int count;
  final String gender;
  final String name;
  final double probability;

  Root({
    required this.count,
    required this.gender,
    required this.name,
    required this.probability,
  });

  factory Root.fromJson(Map<String, dynamic> json) {
    return Root(
      count: json['count'],
      gender: json['gender'],
      name: json['name'],
      probability: json['probability'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'count': count,
      'gender': gender,
      'probability': probability,
    };
  }
}

void main() {
  getName();
  printNamesWithLetters('m'); // Замініть 'n' на бажану букву
  saveToTextFile();
}

void getName() {
  String name = 'toma'; // Замініть на потрібне вам ім'я
  getUserDetails(name).then((user) {
    print('Name: ${user.name}');
    print('Gender: ${user.gender}');
    print('Probability: ${user.probability}');
    saveToDatabase(user);
  }).catchError((error) {
  });
}

Future<Root> getUserDetails(String name) async {
  String apiUrl = 'https://api.genderize.io?name=$name';
  http.Response response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    return Root.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Error');
  }
}

void saveToDatabase(Root user) {
  final db = sqlite3.open('database.db');

  db.execute('''
    CREATE TABLE IF NOT EXISTS names (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT PRIMARY KEY ON CONFLICT REPLACE,
      count INTEGER,
      gender TEXT,
      probability REAL
    )
  ''');

  db.execute('''
    INSERT INTO names (name, count, gender, probability)
    VALUES (?, ?, ?, ?)
  ''', [user.name, user.count, user.gender, user.probability]);

  db.dispose();
  saveToTextFile();
}
void printNamesWithLetters(String letters) {
  final db = sqlite3.open('database.db');

  final results = db.select(
    'SELECT name, count, gender, probability FROM names WHERE name LIKE ?',
    ['%$letters%'],
  );

  if (results.isNotEmpty) {

    print('Names with letters "$letters":');
    for (final row in results) {
      print('Name: ${row['name']}');
      print('Gender: ${row['gender']}');
      print('Count: ${row['count']}');
      print('Probability: ${row['probability']}');
      print('');
    }
  } else {
    print('No names with letters "$letters".');
  }

}
void saveToTextFile() {
  final db = sqlite3.open('database.db');

  final result = db.select('SELECT * FROM names');

  final file = File('names.txt');
  if (!file.existsSync()) {
    file.createSync();
  } else {
    file.writeAsStringSync('');
  }

  final sink = file.openWrite();
  for (final row in result) {
    sink.writeln(
        'Name: ${row['name']}, '
        'Count: ${row['count']}, '
        'Gender: ${row['gender']}, '
        'Probability: ${row['probability']}');
  }

  sink.close();
  print('File created/updated');
}


