import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class CategoryForm extends StatefulWidget {
  @override
  _CategoryFormState createState() => _CategoryFormState();
}

class _CategoryFormState extends State<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  String _categoryName = '';
  late DatabaseReference _categoryRef;
  late Stream<DatabaseEvent> _categoriesStream;

  @override
  void initState() {
    super.initState();
    _categoryRef = FirebaseDatabase.instance.ref().child('categories');
    _categoriesStream = _categoryRef.onValue;
  }

  Future<void> _submitCategory() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final categoryRef = _categoryRef.push();
      await categoryRef.set({
        'name': _categoryName,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Category added successfully')));
      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Category',),
              SizedBox(height: 16.0),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTextFormField(
                      label: 'Category Name',
                      onSaved: (value) => _categoryName = value!,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a category name' : null,
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _submitCategory,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32.0),
              Text('Category List', ),
              SizedBox(height: 16.0),
              StreamBuilder<DatabaseEvent>(
                stream: _categoriesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    final categories = data.values.map((value) => value['name'] as String).toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(), // Prevent scrolling in the list view
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(categories[index]),
                        );
                      },
                    );
                  }
                },
              ),
            ],
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
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }
}
