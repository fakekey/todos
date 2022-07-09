import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

@immutable
class Todo {
  final String id;
  final String description;
  final bool isCompleted;

  const Todo({
    required this.id,
    required this.description,
    this.isCompleted = false,
  });

  @override
  String toString() {
    return 'Todo(description: $description, isCompleted: $isCompleted)';
  }
}

class TodoList extends StateNotifier<List<Todo>> {
  TodoList([List<Todo>? initTodos]) : super(initTodos ?? []);

  void add(String description) {
    state = [
      ...state,
      Todo(
        id: uuid.v4(),
        description: description,
      ),
    ];
  }

  void remove(Todo target) {
    state = state.where((todo) => todo.id != target.id).toList();
  }

  void toggle(String id) {
    state = state
        .map((todo) => todo.id == id
            ? Todo(
                id: todo.id,
                isCompleted: !todo.isCompleted,
                description: todo.description,
              )
            : todo)
        .toList();
  }

  void edit({required String id, required String description}) {
    state = state
        .map((todo) => todo.id == id
            ? Todo(
                id: todo.id,
                isCompleted: todo.isCompleted,
                description: description,
              )
            : todo)
        .toList();
  }
}
