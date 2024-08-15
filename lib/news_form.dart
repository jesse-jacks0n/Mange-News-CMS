import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';

class NewsForm extends StatefulWidget {
  @override
  _NewsFormState createState() => _NewsFormState();
}

class _NewsFormState extends State<NewsForm> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _content = '';
  String _author = '';
  DateTime _date = DateTime.now();
  String _category = '';
  dynamic _image;
  List<String> _categories = [];

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('categories').get();
      if (snapshot.exists) {
        Map<dynamic, dynamic> categoriesMap = snapshot.value as Map<dynamic, dynamic>;
        List<String> categories = categoriesMap.values.map<String>((value) {
          return value['name'] as String;
        }).toList();

        setState(() {
          _categories = categories;
        });
      }
    } catch (error) {
      print('Error fetching categories: $error');
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Web: Use image_picker_web
      final pickedFile = await ImagePickerWeb.getImageAsBytes();
      setState(() {
        if (pickedFile != null) {
          _image = pickedFile;
        } else {
          print('No image selected.');
        }
      });
    } else {
      // Mobile: Use image_picker
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
        } else {
          print('No image selected.');
        }
      });
    }
  }

  Future<void> _uploadImageAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        String imageUrl = '';
        if (_image != null) {
          final fileName = DateTime.now().millisecondsSinceEpoch.toString();
          final storageRef = FirebaseStorage.instance.ref().child('news_images/$fileName');

          if (kIsWeb) {
            // Web: Upload image as Uint8List
            final uploadTask = storageRef.putData(Uint8List.fromList(_image as List<int>));
            await uploadTask.whenComplete(() => {});
          } else {
            // Mobile: Upload image as File
            final uploadTask = storageRef.putFile(_image as File);
            await uploadTask.whenComplete(() => {});
          }

          imageUrl = await storageRef.getDownloadURL();
        }

        final newsRef = FirebaseDatabase.instance.ref().child('news').push();
        await newsRef.set({
          'title': _title,
          'description': _description,
          'content': _content,
          'author': _author,
          'date': _date.toIso8601String(),
          'category': _category,
          'imageUrl': imageUrl,
        });

        // Send FCM notification
        await _sendNotification(_title, _description);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('News posted successfully')));
        _formKey.currentState!.reset();
        setState(() {
          _image = null;
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post news: $error')));
      }
    }
  }

  Future<void> _sendNotification(String title, String body) async {
    final serverKey = 'YOUR_SERVER_KEY';
    final fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    final response = await http.post(
      Uri.parse(fcmUrl),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(<String, dynamic>{
        'notification': <String, dynamic>{
          'body': body,
          'title': title,
        },
        'priority': 'high',
        'to': '/topics/news',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send FCM notification');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define breakpoints
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine max width based on screen width
    final maxWidth = screenWidth > 1200
        ? 800.0
        : screenWidth > 800
        ? 600.0
        : double.infinity;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextFormField(
                  label: 'Title',
                  onSaved: (value) => _title = value!,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                ),
                SizedBox(height: 15,),
                _buildTextFormField(
                  label: 'Description',
                  onSaved: (value) => _description = value!,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                  maxLines: 3
                ),
                SizedBox(height: 15,),
                _buildTextFormField(
                  label: 'Content',
                  onSaved: (value) => _content = value!,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter content' : null,
                  maxLines: 10,
                ),
                SizedBox(height: 15,),
                _buildTextFormField(
                  label: 'Author',
                  onSaved: (value) => _author = value!,
                  validator: (value) => value == null || value.isEmpty ? 'Please enter an author' : null,
                ),
                SizedBox(height: 15,),
                _buildDateField(
                  context,
                  initialDate: _date,
                ),
                SizedBox(height: 15,),
                _buildCategoryDropdown(),
                SizedBox(height: 16.0),
                _image == null
                    ? Text('No image selected.')
                    : kIsWeb
                    ? Image.memory(Uint8List.fromList(_image as List<int>))
                    : Image.file(_image as File),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: Text('Select Image'),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _uploadImageAndSubmit,
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build text form field widget
  Widget _buildTextFormField({
    required String label,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      onSaved: onSaved,
      validator: validator,
      maxLines: maxLines,
    );
  }

  // Build date picker field widget
  Widget _buildDateField(BuildContext context, {required DateTime initialDate}) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: 'Date',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null && picked != _date) {
          setState(() {
            _date = picked;
          });
        }
      },
      readOnly: true,
      controller: TextEditingController(text: _date.toIso8601String().split('T').first),
    );
  }

  // Build category dropdown widget
  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _category.isEmpty ? null : _category,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _category = value ?? '';
        });
      },
      validator: (value) => value == null || value.isEmpty ? 'Please select a category' : null,
    );
  }
}
