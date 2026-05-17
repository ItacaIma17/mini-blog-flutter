import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// La URL del backend se pasa en tiempo de compilación con --dart-define
// Ejemplo: flutter build web --dart-define=API_URL=https://mi-backend.onrender.com
const String apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8000',
);

void main() => runApp(const MiniBlogApp());

class MiniBlogApp extends StatelessWidget {
  const MiniBlogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini Blog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const NotesPage(),
    );
  }
}

class Note {
  final int id;
  final String title;
  final String content;
  final String createdAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as int,
        title: json['title'] as String,
        content: json['content'] as String,
        createdAt: json['created_at'] as String,
      );
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> _notes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(Uri.parse('$apiUrl/notes'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _notes = data
              .map((e) => Note.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error ${res.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'No se puede conectar con el backend:\n$e';
        _loading = false;
      });
    }
  }

  Future<void> _createNote(String title, String content) async {
    final res = await http.post(
      Uri.parse('$apiUrl/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content}),
    );
    if (res.statusCode == 201) {
      _loadNotes();
    }
  }

  Future<void> _deleteNote(int id) async {
    final res = await http.delete(Uri.parse('$apiUrl/notes/$id'));
    if (res.statusCode == 204) {
      _loadNotes();
    }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva nota'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Título'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentCtrl,
              decoration: const InputDecoration(labelText: 'Contenido'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty ||
                  contentCtrl.text.trim().isEmpty) {
                return;
              }
              Navigator.pop(ctx);
              _createNote(titleCtrl.text.trim(), contentCtrl.text.trim());
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Blog'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadNotes,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva nota'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadNotes,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_notes.isEmpty) {
      return const Center(
        child: Text('No hay notas todavía. ¡Crea la primera!'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _notes.length,
      itemBuilder: (ctx, i) {
        final n = _notes[i];
        return Card(
          child: ListTile(
            title: Text(
              n.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(n.content),
                const SizedBox(height: 6),
                Text(
                  n.createdAt,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteNote(n.id),
            ),
          ),
        );
      },
    );
  }
}
