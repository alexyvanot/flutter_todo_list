import 'package:flutter/cupertino.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final List<TodoItem> _todos = [];
  final TextEditingController _controller = TextEditingController();

  // ajouter un todo
  void _addTodo() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _todos.add(TodoItem(title: _controller.text, isDone: false));
        _controller.clear(); // nettoyage du champ de texte apres l'ajout du todo
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Todo List'),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
            child: CupertinoTextField(
              controller: _controller,
              placeholder: 'Ex: Ne pas oublier de...',
            ),
          ),
          CupertinoButton.filled(
            onPressed: _addTodo, // Appel de la fonction pour ajouter une tâche
            child: const Text('Ajouter'),
          ),
          // ajouter ici la liste des todos plus tard
        ],
      ),
    );
  }
}

// structure d'un todo
class TodoItem {
  final String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}
