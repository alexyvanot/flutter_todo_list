import 'package:flutter/cupertino.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Todo List'),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
              child: CupertinoTextField(
                placeholder: 'Ajouter un todo',
              ),
            ),
            CupertinoButton.filled(
              onPressed: () {
                // appel de fonction pour ajouter un todo
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }
}