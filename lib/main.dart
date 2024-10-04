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

  // called at the start of the app
  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  // load from key map todos
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

  // save en json and key map to "todos"
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

  @override
  Widget build(BuildContext context) {
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
          Expanded(
            child: ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onLongPress: () {
                    setState(() {
                      _todos.removeAt(index);
                      _saveTodos();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _todos[index].isDone = !_todos[index].isDone;
                                _saveTodos();
                              });
                            },
                            child: Text(
                              _todos[index].title,
                              style: TextStyle(
                                decoration: _todos[index].isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        CupertinoSwitch(
                          value: _todos[index].isDone,
                          onChanged: (value) {
                            setState(() {
                              _todos[index].isDone = value;
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
}

class TodoItem {
  final String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}
