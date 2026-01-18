import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/firestore_service.dart';
import '../widgets/teacher_card.dart';
import 'add_teacher_screen.dart';
import 'teacher_details_screen.dart';

class TeachersListScreen extends StatelessWidget {
  const TeachersListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הצוות שלי'),
          backgroundColor: const Color(0xFF11a0db),
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<List<Teacher>>(
          stream: firestoreService.getTeachersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text('שגיאה: ${snapshot.error}'),
              );
            }

            final teachers = snapshot.data ?? [];

            if (teachers.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'אין מורים ברשימה',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'הוסף מורה ראשון',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                return TeacherCard(
                  teacher: teacher,
                  actionsCount: 0, // TODO: להוסיף ספירת פעולות
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeacherDetailsScreen(
                          teacherId: teacher.id,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddTeacherScreen(),
              ),
            );
          },
          backgroundColor: const Color(0xFF11a0db),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}

