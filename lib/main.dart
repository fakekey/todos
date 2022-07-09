import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:todos/todo.dart';

void main() => runApp(const ProviderScope(child: App()));

final todoList = StateNotifierProvider<TodoList, List<Todo>>((ref) {
  return TodoList();
});

final _currentTodo = Provider<Todo>((ref) {
  throw UnimplementedError();
});

final _currentTodosLeft = Provider<int>((ref) {
  return ref.watch(todoList).where((todo) => !todo.isCompleted).length;
});

enum TodoListFilter {
  all,
  uncompleted,
  completed,
}

final currentTodoFilter = StateProvider(((ref) => TodoListFilter.all));

final todoListFiltered = Provider<List<Todo>>((ref) {
  final filter = ref.watch(currentTodoFilter);
  final todos = ref.watch(todoList);

  switch (filter) {
    case TodoListFilter.all:
      return todos;
    case TodoListFilter.uncompleted:
      return todos.where((todo) => !todo.isCompleted).toList();
    case TodoListFilter.completed:
      return todos.where((todo) => todo.isCompleted).toList();
  }
});

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends HookConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputController = useTextEditingController();
    final todos = ref.watch(todoListFiltered);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
          children: [
            const AppTitle(title: 'todos'),
            TextField(
              controller: inputController,
              decoration: const InputDecoration(
                labelText: 'What needs to be done?',
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  ref.read(todoList.notifier).add(value.trim());
                }
                inputController.clear();
              },
            ),
            const SizedBox(height: 42),
            const ToolBar(),
            if (todos.isNotEmpty) const Divider(height: 0),
            for (var i = 0; i < todos.length; i++) ...[
              if (i > 0) const Divider(height: 0),
              Dismissible(
                key: ValueKey(todos[i].id),
                onDismissed: (dismissDirection) {
                  ref.read(todoList.notifier).remove(todos[i]);
                },
                child: ProviderScope(
                  overrides: [_currentTodo.overrideWithValue(todos[i])],
                  child: const TodoItem(),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class AppTitle extends StatelessWidget {
  final String title;

  const AppTitle({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Color.fromARGB(136, 47, 47, 247),
        fontSize: 100,
        fontWeight: FontWeight.w100,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}

class ToolBar extends HookConsumerWidget {
  const ToolBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(currentTodoFilter);

    Color? textColorFor(TodoListFilter filter) {
      return currentFilter == filter ? Colors.blue : Colors.black;
    }

    return Material(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${ref.watch(_currentTodosLeft)} todo(s) left',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            message: 'All todos',
            child: TextButton(
              onPressed: () {
                ref.read(currentTodoFilter.notifier).state = TodoListFilter.all;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor:
                    MaterialStateProperty.all(textColorFor(TodoListFilter.all)),
              ),
              child: const Text('All'),
            ),
          ),
          Tooltip(
            message: 'Only uncompleted todos',
            child: TextButton(
              onPressed: () {
                ref.read(currentTodoFilter.notifier).state =
                    TodoListFilter.uncompleted;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                    textColorFor(TodoListFilter.uncompleted)),
              ),
              child: const Text('Uncompleted'),
            ),
          ),
          Tooltip(
            message: 'Only completed todos',
            child: TextButton(
              onPressed: () {
                ref.read(currentTodoFilter.notifier).state =
                    TodoListFilter.completed;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                    textColorFor(TodoListFilter.completed)),
              ),
              child: const Text('Completed'),
            ),
          ),
        ],
      ),
    );
  }
}

class TodoItem extends HookConsumerWidget {
  const TodoItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTodo = ref.watch(_currentTodo);
    final todoFocusNode = useFocusNode();
    final descriptionFocusNode = useFocusNode();
    final descriptionController = useTextEditingController();
    final isFocused = useState(false);

    useEffect(() {
      void listener() {
        isFocused.value = todoFocusNode.hasFocus;
      }

      todoFocusNode.addListener(listener);
      return () {
        todoFocusNode.removeListener(listener);
      };
    }, [todoFocusNode]);

    return Material(
      color: Colors.white,
      elevation: 4,
      child: Focus(
        focusNode: todoFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            descriptionController.text = currentTodo.description;
          } else {
            ref.read(todoList.notifier).edit(
                  id: currentTodo.id,
                  description: descriptionController.text.trim(),
                );
          }
        },
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ListTile(
            onTap: () {
              todoFocusNode.requestFocus();
              descriptionFocusNode.requestFocus();
            },
            leading: Checkbox(
              value: currentTodo.isCompleted,
              onChanged: (value) {
                ref.read(todoList.notifier).toggle(currentTodo.id);
              },
            ),
            title: isFocused.value
                ? TextField(
                    autofocus: true,
                    decoration: const InputDecoration(border: InputBorder.none),
                    focusNode: descriptionFocusNode,
                    controller: descriptionController,
                  )
                : Text(currentTodo.description),
          ),
        ),
      ),
    );
  }
}
