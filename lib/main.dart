import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
  String _filter = 'all';

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

  Future<bool?> _confirmDelete(TodoItem todo) async {
    bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Confirmation de Suppression'),
          content: Text('Êtes-vous sûr de vouloir supprimer "${todo.title}" ?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            CupertinoDialogAction(
              child: const Text(
                'Supprimer',
                style: TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    return confirm;
  }

  @override
  Widget build(BuildContext context) {
    List<TodoItem> filteredTodos = _filter == 'completed'
        ? _todos.where((todo) => todo.isDone).toList()
        : _filter == 'incomplete'
            ? _todos.where((todo) => !todo.isDone).toList()
            : _todos;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Flutter Todo List'),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.only(top: 50.0, bottom: 15.0),
                  child: CupertinoTextField(
                    controller: _controller,
                    placeholder: 'Ex: Ne pas oublier de...',
                  ),
                ),
              ),
              CupertinoButton.filled(
                onPressed: _addTodo,
                child: const Text(
                  'Ajouter',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18.0,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildFilterButton('all', 'Tous'),
                    _buildFilterButton('completed', 'Complètes'),
                    _buildFilterButton('incomplete', 'Incomplètes'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView.builder(
                    itemCount: filteredTodos.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(filteredTodos[index].title),
                        background: Container(
                          color: CupertinoColors.destructiveRed,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ),
                        secondaryBackground: Container(
                          color: CupertinoColors.destructiveRed,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.endToStart) {
                            return await _confirmDelete(filteredTodos[index]);
                          }
                          return false;
                        },
                        onDismissed: (direction) {
                          if (direction == DismissDirection.endToStart) {
                            setState(() {
                              _todos.remove(filteredTodos[index]);
                              _saveTodos();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterButton(String filterValue, String label) {
    bool isSelected = _filter == filterValue;
    return isSelected
        ? Container(
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 16.0,
              ),
            ),
          )
        : GestureDetector(
            onTap: () => _filterTodos(filterValue),
            child: Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.inactiveGray,
                fontSize: 16.0,
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
