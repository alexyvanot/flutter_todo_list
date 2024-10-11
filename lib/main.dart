import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => TodoProvider(),
      child: const MyApp(),
    ),
  );
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

class TodoListScreen extends StatelessWidget {
  const TodoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final todoProvider = Provider.of<TodoProvider>(context);
    List<TodoItem> filteredTodos = todoProvider.filteredTodos;

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
                    controller: todoProvider.controller,
                    placeholder: 'Ex: Ne pas oublier de...',
                  ),
                ),
              ),
              CupertinoButton.filled(
                onPressed: todoProvider.addTodo,
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
                    _buildFilterButton(context, 'all', 'Tous'),
                    _buildFilterButton(context, 'completed', 'Complètes'),
                    _buildFilterButton(context, 'incomplete', 'Incomplètes'),
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
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: const Text(
                            'Supprimer',
                            style: TextStyle(color: CupertinoColors.white),
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await _confirmDelete(context, filteredTodos[index]);
                        },
                        onDismissed: (direction) {
                          todoProvider.removeTodo(filteredTodos[index]);
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
                                    todoProvider.toggleTodoCompletion(filteredTodos[index]);
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
                                  todoProvider.toggleTodoCompletion(filteredTodos[index]);
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

  Widget _buildFilterButton(BuildContext context, String filterValue, String label) {
    final todoProvider = Provider.of<TodoProvider>(context);
    final isSelected = todoProvider.filter == filterValue;

    return GestureDetector(
      onTap: () {
        todoProvider.setFilter(filterValue);
      },
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(10),
              )
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : CupertinoColors.inactiveGray,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, TodoItem todo) async {
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
}

class TodoProvider extends ChangeNotifier {
  final List<TodoItem> _todos = [];
  String _filter = 'all';
  final TextEditingController _controller = TextEditingController();

  TextEditingController get controller => _controller;

  List<TodoItem> get filteredTodos {
    if (_filter == 'completed') {
      return _todos.where((todo) => todo.isDone).toList();
    } else if (_filter == 'incomplete') {
      return _todos.where((todo) => !todo.isDone).toList();
    }
    return _todos;
  }

  String get filter => _filter;

  TodoProvider() {
    _loadTodos();
  }

  void addTodo() {
    if (_controller.text.isNotEmpty) {
      _todos.add(TodoItem(title: _controller.text));
      _controller.clear();
      _saveTodos();
      notifyListeners();
    }
  }

  void removeTodo(TodoItem todo) {
    _todos.remove(todo);
    _saveTodos();
    notifyListeners();
  }

  void toggleTodoCompletion(TodoItem todo) {
    todo.isDone = !todo.isDone;
    _saveTodos();
    notifyListeners();
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Future<void> _loadTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? todoList = prefs.getStringList('todos');
    if (todoList != null) {
      _todos.clear();
      _todos.addAll(todoList.map((item) {
        final todoData = jsonDecode(item);
        return TodoItem(title: todoData['title'], isDone: todoData['isDone']);
      }));
      notifyListeners();
    }
  }

  Future<void> _saveTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> todoList = _todos.map((todo) {
      return jsonEncode({'title': todo.title, 'isDone': todo.isDone});
    }).toList();
    await prefs.setStringList('todos', todoList);
  }
}

class TodoItem {
  final String title;
  bool isDone;

  TodoItem({required this.title, this.isDone = false});
}
