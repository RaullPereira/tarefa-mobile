import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'task.dart';
import 'task_form_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Adicionar ou Editar uma tarefa no Firestore
  void _addOrEditTask(Task task, {String? id}) {
    if (id == null) {
      _firestore.collection('tasks').add({
        'title': task.title,
        'difficulty': task.difficulty,
        'level': task.level,
        'imageUrl': task.imageUrl,
      });
    } else {
      _firestore.collection('tasks').doc(id).update({
        'title': task.title,
        'difficulty': task.difficulty,
        'level': task.level,
        'imageUrl': task.imageUrl,
      });
    }
  }

  // Deletar uma tarefa
  void _deleteTask(String id) {
    _firestore.collection('tasks').doc(id).delete();
  }

  // Atualizar o nível no Firestore
  void _updateTaskLevel(Task task) {
    task.levelUp();
    _firestore.collection('tasks').doc(task.id).update({
      'level': task.level,
    });
  }

  // Navegar para o formulário de edição
  void _navigateToForm({Task? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormPage(
          task: task,
          onSave: (newTask) => _addOrEditTask(newTask, id: task?.id),
        ),
      ),
    );
  }

  Widget _defaultImage() {
    return Container(
      width: 50,
      height: 50,
      color: Colors.grey[300],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciador de Tarefas'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tasks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!.docs.map((doc) {
            return Task(
              id: doc.id,
              title: doc['title'] ?? 'Sem título',
              difficulty: doc['difficulty'] ?? 1,
              level: doc['level'] ?? 0,
              imageUrl: doc['imageUrl'] ?? '',
            );
          }).toList();

          return tasks.isEmpty
              ? const Center(child: Text('Nenhuma tarefa cadastrada!'))
              : ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: SizedBox(
                          width: 50,
                          height: 50,
                          child: task.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    task.imageUrl,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _defaultImage(),
                        ),
                        title: Text(
                          task.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: List.generate(
                                task.difficulty,
                                (index) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Nível: ${task.level} / ${task.maxLevel}'),
                            LinearProgressIndicator(
                              value: task.level / task.maxLevel,
                              backgroundColor: Colors.grey[300],
                              color: Colors.blueAccent,
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _navigateToForm(task: task);
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Confirmar Exclusão'),
                                    content: const Text(
                                        'Tem certeza de que deseja excluir esta tarefa?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteTask(task.id);
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            } else if (value == 'levelUp') {
                              setState(() {
                                _updateTaskLevel(task);
                              });
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Editar'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'delete',
                              child: ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Excluir'),
                              ),
                            ),
                            const PopupMenuItem<String>(
                              value: 'levelUp',
                              child: ListTile(
                                leading: Icon(Icons.arrow_upward),
                                title: Text('Aumentar Nível'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(),
        backgroundColor: const Color(0xFF4D4DFF),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
