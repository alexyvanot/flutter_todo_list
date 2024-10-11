import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart'; // save feature
import 'dart:convert'; // pour json

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
  String _filter = 'all'; // filtrage des todo

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? todoList = prefs.getStringList('todos');
    if (todoList != null) {
      setState(() {
        _todos.clear();
        _todos.addAll(todoList.map((item) {
          final todoData = jsonDecode(item);
          return TodoItem(title: todoData['title'], isDone: todoData['isDone']);
        }));
      });
    }
  }

  Future<void> _saveTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todoList = _todos.map((todo) {
      return jsonEncode({'title': todo.title, 'isDone': todo.isDone});
    }).toList();
    await prefs.setStringList('todos', todoList);
  }

  void _addTodo() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _todos.add(TodoItem(title: _controller.text, isDone: false));
        _controller.clear();
        _saveTodos();
      });
    }
  }

  void _filterTodos(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtrer les tâches
    List<TodoItem> filteredTodos = _filter == 'completed'
        ? _todos.where((todo) => todo.isDone).toList()
        : _filter == 'incomplete'
            ? _todos.where((todo) => !todo.isDone).toList()
            : _todos;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Flutter Todo List'),
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
            onPressed: _addTodo,
            child: const Text('Ajouter'),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFilterButton('all', 'Tous'),
              _buildFilterButton('completed', 'Complètes'),
              _buildFilterButton('incomplete', 'Incomplètes'),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredTodos.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: Key(filteredTodos[index].title),
                  background: Container(color: CupertinoColors.destructiveRed),
                  onDismissed: (direction) {
                    setState(() {
                      _todos.remove(filteredTodos[index]);
                      _saveTodos();
                    });
                    // Cupertino Dialog pour la confirmation de suppression
                    CupertinoAlertDialog alert = CupertinoAlertDialog(
                      title: const Text('Todo supprimée'),
                      content: Text("${filteredTodos[index].title} a été supprimée."),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('OK'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                    showCupertinoDialog(
                      context: context,
                      builder: (context) => alert,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                filteredTodos[index].isDone = !filteredTodos[index].isDone;
                                _saveTodos();
                              });
                            },
                            child: Text(
                              filteredTodos[index].title,
                              style: TextStyle(
                                decoration: filteredTodos[index].isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: filteredTodos[index].isDone,
                          onChanged: (value) {
                            setState(() {
                              filteredTodos[index].isDone = value;
                              _saveTodos();
                            });
                          },
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

  Widget _buildFilterButton(String filterValue, String label) {
    bool isSelected = _filter == filterValue;
    return isSelected
        ? Container(
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
              ),
            ),
          )
        : GestureDetector(
            onTap: () => _filterTodos(filterValue),
            child: Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.activeBlue,
              ),
            ),
          );
  }
}

class TodoItem {
  final String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}
