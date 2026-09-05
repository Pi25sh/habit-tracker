import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/providers/task_provider.dart';
import '../../data/models/task.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  final Task? editTask;

  const CreateTaskScreen({super.key, this.editTask});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _dueDate = DateTime.now();
  TimeOfDay? _dueTime;
  String _repeat = 'Daily';

  final List<String> _repeatOptions = ['None', 'Daily', 'Weekly', 'Monthly'];

  bool get _isEdit => widget.editTask != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final t = widget.editTask!;
      _nameController.text = t.name;
      _noteController.text = t.note ?? '';
      _dueDate = t.dueDate ?? DateTime.now();
      _dueTime = t.dueTime;
      // We don't have a repeat field on Task in the backend, but we keep it for UI fidelity
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF529367),
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickDueTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: const Color(0xFF529367),
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final task = Task(
      id: widget.editTask?.id ?? now.millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      description: widget.editTask?.description,
      icon: widget.editTask?.icon ?? '📋',
      color: widget.editTask?.color ?? const Color(0xFFAFC8B3).toARGB32(),
      isCompleted: widget.editTask?.isCompleted ?? false,
      dueDate: _dueDate,
      dueTime: _dueTime,
      reminderTime: widget.editTask?.reminderTime,
      priority: widget.editTask?.priority ?? 'Medium',
      category: widget.editTask?.category ?? 'Personal',
      createdAt: widget.editTask?.createdAt ?? now,
      updatedAt: now,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      imagePaths: widget.editTask?.imagePaths,
      doodlePaths: widget.editTask?.doodlePaths,
    );

    if (_isEdit) {
      ref.read(taskProvider.notifier).updateTask(task);
    } else {
      ref.read(taskProvider.notifier).addTask(task);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // Warm off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8DA989)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          _isEdit ? 'Edit Todo' : 'Add Todo',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            child: InkWell(
              onTap: _save,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF8DA989),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "What to do?" input
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8DA989), width: 1.5),
                ),
                child: TextFormField(
                  controller: _nameController,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter a task name' : null,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'What to do?',
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontSize: 18,
                    ),
                    prefixIcon: Icon(Icons.edit, color: Color(0xFF8DA989)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.black12, height: 1),
              const SizedBox(height: 24),

              // Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, color: Colors.black54),
                      SizedBox(width: 12),
                      Text(
                        'Date',
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAFC8B3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('dd MMM yyyy').format(_dueDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.black12, height: 1),
              const SizedBox(height: 24),

              // Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.black54),
                      SizedBox(width: 12),
                      Text(
                        'Time',
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _pickDueTime,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFAFC8B3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _dueTime != null ? _dueTime!.format(context) : 'Add Time',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.black12, height: 1),
              const SizedBox(height: 24),

              // Repeat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Repeat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF8DA989), width: 1.5),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _repeat,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8DA989)),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        items: _repeatOptions.map((String val) {
                          return DropdownMenuItem(
                            value: val,
                            child: Text(val),
                          );
                        }).toList(),
                        onChanged: (String? newVal) {
                          if (newVal != null) setState(() => _repeat = newVal);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.black12, height: 1),
              const SizedBox(height: 24),

              // Notes
              const Text(
                'Notes (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F7F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF8DA989), width: 1.5),
                ),
                child: TextFormField(
                  controller: _noteController,
                  maxLines: 6,
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'Add a note...',
                    hintStyle: TextStyle(
                      color: Colors.black38,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
