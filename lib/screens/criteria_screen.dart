import 'package:flutter/material.dart';
import '../models/models.dart';

class CriteriaScreen extends StatefulWidget {
  const CriteriaScreen({super.key});

  @override
  State<CriteriaScreen> createState() => _CriteriaScreenState();
}

class _CriteriaScreenState extends State<CriteriaScreen> {
  final List<Kriteria> _criteria = [];

  void _addCriterion() {
    showDialog(
      context: context,
      builder: (context) => AddCriterionDialog(
        onAdd: (criterion) {
          setState(() {
            _criteria.add(criterion);
          });
        },
      ),
    );
  }

  void _editCriterion(Kriteria criterion) {
    showDialog(
      context: context,
      builder: (context) => AddCriterionDialog(
        criterion: criterion,
        onAdd: (updatedCriterion) {
          setState(() {
            final index = _criteria.indexWhere((c) => c.id == criterion.id);
            if (index != -1) {
              _criteria[index] = updatedCriterion;
            }
          });
        },
      ),
    );
  }

  void _deleteCriterion(Kriteria criterion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Criterion'),
        content: Text('Are you sure you want to delete "${criterion.nama}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _criteria.remove(criterion);
              });
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _criteria.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.list_alt,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No criteria added yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add evaluation criteria to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _criteria.length,
              itemBuilder: (context, index) {
                final criterion = _criteria[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(criterion.nama),
                    subtitle: Text(criterion.jenis.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editCriterion(criterion),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteCriterion(criterion),
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCriterion,
        tooltip: 'Add Criterion',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddCriterionDialog extends StatefulWidget {
  final Kriteria? criterion;
  final Function(Kriteria) onAdd;

  const AddCriterionDialog({
    super.key,
    this.criterion,
    required this.onAdd,
  });

  @override
  State<AddCriterionDialog> createState() => _AddCriterionDialogState();
}

class _AddCriterionDialogState extends State<AddCriterionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.criterion != null) {
      _nameController.text = widget.criterion!.nama;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final criterion = Kriteria(
        id: widget.criterion?.id ?? DateTime.now().toString(),
        nama: _nameController.text.trim(),
        jenis: JenisKriteria.benefit,
      );
      widget.onAdd(criterion);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.criterion == null ? 'Add Criterion' : 'Edit Criterion'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Criterion Name',
                hintText: 'e.g., Academic Performance',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(widget.criterion == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}