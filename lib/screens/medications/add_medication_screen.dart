import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/medication_service.dart';
import '../../models/medication.dart';

class AddMedicationScreen extends StatefulWidget {
  final int? medicationId;
  
  const AddMedicationScreen({
    super.key,
    this.medicationId,
  });

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _totalQuantityController = TextEditingController();
  final TextEditingController _remainingQuantityController = TextEditingController();
  
  DosageUnit _selectedDosageUnit = DosageUnit.tablet;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<Schedule> _schedules = [];
  
  bool _isLoading = false;
  bool _isEditing = false;
  Medication? _existingMedication;
  
  @override
  void initState() {
    super.initState();
    _isEditing = widget.medicationId != null;
    
    // If editing, fetch the medication data
    if (_isEditing) {
      _loadMedicationData();
    } else {
      // Default schedule for new medications
      _schedules = [
        Schedule(
          timeOfDay: const TimeOfDay(hour: 8, minute: 0),
          daysOfWeek: [1, 2, 3, 4, 5, 6, 7], // Every day
        ),
      ];
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _instructionsController.dispose();
    _totalQuantityController.dispose();
    _remainingQuantityController.dispose();
    super.dispose();
  }
  
  // Load existing medication data
  Future<void> _loadMedicationData() async {
    setState(() {
      _isLoading = true;
    });
    
    final medicationService = Provider.of<MedicationService>(context, listen: false);
    
    try {
      await medicationService.loadMedications();
      
      final medication = medicationService.medications.firstWhere(
        (med) => med.id == widget.medicationId,
      );
      
      _existingMedication = medication;
      
      // Populate form fields
      _nameController.text = medication.name;
      _dosageController.text = medication.dosage.toString();
      _selectedDosageUnit = medication.dosageUnit;
      _instructionsController.text = medication.instructions;
      _totalQuantityController.text = medication.totalQuantity.toString();
      _remainingQuantityController.text = medication.remainingQuantity.toString();
      _startDate = medication.startDate;
      _endDate = medication.endDate;
      _schedules = medication.schedules;
      
    } catch (e) {
      // Show error message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading medication: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Save medication
  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate() || _schedules.isEmpty) {
      if (_schedules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add at least one schedule'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final medicationService = Provider.of<MedicationService>(context, listen: false);
      
      // Create medication object
      final medication = Medication(
        id: _isEditing ? widget.medicationId : null,
        name: _nameController.text,
        dosage: double.parse(_dosageController.text),
        dosageUnit: _selectedDosageUnit,
        instructions: _instructionsController.text,
        frequency: _schedules.length,
        totalQuantity: int.parse(_totalQuantityController.text),
        remainingQuantity: int.parse(_remainingQuantityController.text),
        startDate: _startDate,
        endDate: _endDate,
        schedules: _schedules,
        logs: _isEditing ? _existingMedication!.logs : [],
      );
      
      if (_isEditing) {
        await medicationService.updateMedication(medication);
      } else {
        await medicationService.addMedication(medication);
      }
      
      if (!mounted) return;
      
      Navigator.pop(context);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Medication ${_isEditing ? 'updated' : 'added'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving medication: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Add or edit a schedule
  void _showScheduleDialog({Schedule? existingSchedule, int? editIndex}) {
    final TimeOfDay initialTime = existingSchedule?.timeOfDay ?? 
        const TimeOfDay(hour: 8, minute: 0);
    final List<int> initialDays = existingSchedule?.daysOfWeek ?? 
        [1, 2, 3, 4, 5, 6, 7];
    
    // Create temporary variables for editing
    TimeOfDay selectedTime = initialTime;
    List<bool> selectedDays = List.generate(7, (index) => 
        initialDays.contains(index + 1));
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existingSchedule == null ? 'Add Schedule' : 'Edit Schedule'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time picker button
                  ListTile(
                    title: const Text('Time'),
                    subtitle: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Days of week selection
                  const Text('Days'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDayToggle('M', 0, selectedDays, (value) {
                        setState(() {
                          selectedDays[0] = value;
                        });
                      }),
                      _buildDayToggle('T', 1, selectedDays, (value) {
                        setState(() {
                          selectedDays[1] = value;
                        });
                      }),
                      _buildDayToggle('W', 2, selectedDays, (value) {
                        setState(() {
                          selectedDays[2] = value;
                        });
                      }),
                      _buildDayToggle('T', 3, selectedDays, (value) {
                        setState(() {
                          selectedDays[3] = value;
                        });
                      }),
                      _buildDayToggle('F', 4, selectedDays, (value) {
                        setState(() {
                          selectedDays[4] = value;
                        });
                      }),
                      _buildDayToggle('S', 5, selectedDays, (value) {
                        setState(() {
                          selectedDays[5] = value;
                        });
                      }),
                      _buildDayToggle('S', 6, selectedDays, (value) {
                        setState(() {
                          selectedDays[6] = value;
                        });
                      }),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Convert selected days to list of day indices (1-7)
                    final List<int> days = [];
                    for (int i = 0; i < selectedDays.length; i++) {
                      if (selectedDays[i]) {
                        days.add(i + 1);
                      }
                    }
                    
                    if (days.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one day'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Create schedule
                    final schedule = Schedule(
                      id: existingSchedule?.id,
                      timeOfDay: selectedTime,
                      daysOfWeek: days,
                    );
                    
                    // Update state
                    setState(() {
                      if (editIndex != null) {
                        _schedules[editIndex] = schedule;
                      } else {
                        _schedules.add(schedule);
                      }
                    });
                    
                    Navigator.pop(context);
                  },
                  child: const Text('SAVE'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Helper to build day toggle button
  Widget _buildDayToggle(
    String label, 
    int dayIndex, 
    List<bool> selectedDays,
    ValueChanged<bool> onChanged,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            onChanged(!selectedDays[dayIndex]);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedDays[dayIndex] 
                  ? AppTheme.primaryColor 
                  : Colors.grey.shade200,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selectedDays[dayIndex] ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Medication' : 'Add Medication'),
      ),
      body: _isLoading && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medication Info Section
                    const Text(
                      'Medication Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Medication Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter medication name';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dosage field and unit dropdown
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dosage amount
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _dosageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Dosage',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter dosage';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Enter valid number';
                              }
                              return null;
                            },
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Dosage unit
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<DosageUnit>(
                            value: _selectedDosageUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: DosageUnit.values.map((unit) {
                              return DropdownMenuItem<DosageUnit>(
                                value: unit,
                                child: Text(unit.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedDosageUnit = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Instructions field
                    TextFormField(
                      controller: _instructionsController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Instructions',
                        hintText: 'E.g., Take with food, Take before bedtime',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quantity section
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Total quantity field
                    TextFormField(
                      controller: _totalQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Quantity (${_selectedDosageUnit.name}s)',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter total quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Remaining quantity field
                    TextFormField(
                      controller: _remainingQuantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Remaining Quantity (${_selectedDosageUnit.name}s)',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter remaining quantity';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        
                        final remaining = int.parse(value);
                        final total = int.tryParse(_totalQuantityController.text) ?? 0;
                        
                        if (remaining > total) {
                          return 'Cannot exceed total';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date section
                    const Text(
                      'Schedule',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Start date picker
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormat('MMM d, yyyy').format(_startDate)),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // End date picker (optional)
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? _startDate.add(const Duration(days: 30)),
                          firstDate: _startDate,
                          lastDate: _startDate.add(const Duration(days: 365 * 5)),
                        );
                        setState(() {
                          _endDate = date;
                        });
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Date (Optional)',
                          border: const OutlineInputBorder(),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_endDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _endDate = null;
                                    });
                                  },
                                ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                        child: Text(
                          _endDate != null 
                              ? DateFormat('MMM d, yyyy').format(_endDate!) 
                              : 'No end date',
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Time schedules section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Time Schedules',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          color: AppTheme.primaryColor,
                          onPressed: () {
                            _showScheduleDialog();
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Schedules list
                    if (_schedules.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No schedules added yet. Tap + to add.'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _schedules.length,
                        itemBuilder: (context, index) {
                          final schedule = _schedules[index];
                          
                          // Format time
                          final hour = schedule.timeOfDay.hour;
                          final minute = schedule.timeOfDay.minute.toString().padLeft(2, '0');
                          final period = hour >= 12 ? 'PM' : 'AM';
                          final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
                          final timeString = '$hour12:$minute $period';
                          
                          // Format days
                          final days = schedule.daysOfWeek.map((day) {
                            switch (day) {
                              case 1: return 'Mon';
                              case 2: return 'Tue';
                              case 3: return 'Wed';
                              case 4: return 'Thu';
                              case 5: return 'Fri';
                              case 6: return 'Sat';
                              case 7: return 'Sun';
                              default: return '';
                            }
                          }).join(', ');
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
                              title: Text(timeString),
                              subtitle: Text(days),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _showScheduleDialog(
                                        existingSchedule: schedule,
                                        editIndex: index,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () {
                                      setState(() {
                                        _schedules.removeAt(index);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveMedication,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isEditing ? 'UPDATE MEDICATION' : 'ADD MEDICATION'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}