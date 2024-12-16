import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'task.dart';

class TaskFormPage extends StatefulWidget {
  final Task? task;
  final Function(Task) onSave;

  TaskFormPage({this.task, required this.onSave});

  @override
  _TaskFormPageState createState() => _TaskFormPageState();
}

class _TaskFormPageState extends State<TaskFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late int _difficulty;
  String _imageUrl = '';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _title = widget.task?.title ?? '';
    _difficulty = widget.task?.difficulty ?? 1;
    _imageUrl = widget.task?.imageUrl ?? '';
  }

  // Função para selecionar a imagem da galeria e fazer o upload
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      // Faz o upload da imagem para o ImgBB
      String uploadedImageUrl = await _uploadImageToImgBB(File(pickedFile.path));
      setState(() {
        _imageUrl = uploadedImageUrl;
      });
    }
  }

  Future<String> _uploadImageToImgBB(File imageFile) async {
    const String apiKey = 'bd154aae96f7166a5f72db81f83b71f3';
    final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final jsonResponse = json.decode(responseData);

    if (response.statusCode == 200) {
      return jsonResponse['data']['url'];
    } else {
      throw Exception('Falha ao fazer upload da imagem');
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newTask = Task(
        id: widget.task?.id ?? '',  // Passa o id se for edição ou uma string vazia se for nova
        title: _title,
        difficulty: _difficulty,
        imageUrl: _imageUrl, level: 0,
      );
      widget.onSave(newTask);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Nova Tarefa' : 'Editar Tarefa'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Se houver uma imagem URL, exibe-a. Caso contrário, exibe um ícone padrão.
                Center(
                  child: Column(
                    children: [
                      _imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageUrl,
                                height: 100,
                                width: 100,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 50),
                            ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Selecionar Imagem'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Campo de título da tarefa
                TextFormField(
                  initialValue: _title,
                  decoration: InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Informe um título!' : null,
                  onSaved: (value) => _title = value!,
                ),
                const SizedBox(height: 16),

                // Campo para a dificuldade da tarefa (1 a 5)
                TextFormField(
                  initialValue: _difficulty.toString(),
                  decoration: InputDecoration(
                    labelText: 'Dificuldade (1-5)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final diff = int.tryParse(value!);
                    if (diff == null || diff < 1 || diff > 5) {
                      return 'Informe um valor entre 1 e 5!';
                    }
                    return null;
                  },
                  onSaved: (value) => _difficulty = int.parse(value!),
                ),
                const SizedBox(height: 16),

                // Botão para salvar a tarefa
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D4DFF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saveForm,
                  child: const Text(
                    'Salvar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
