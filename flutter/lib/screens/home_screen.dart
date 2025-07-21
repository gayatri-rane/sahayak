import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../widgets/feature_card.dart';
import 'story_generator_screen.dart';
import 'worksheet_creator_screen.dart';
import 'visual_aid_screen.dart';
import 'game_generator_screen.dart';
import 'lesson_plan_screen.dart';
import 'student_progress_screen.dart';
import 'community_library_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahayak'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.library_books),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityLibraryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            FeatureCard(
              title: 'Story Generator',
              icon: Icons.book,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StoryGeneratorScreen(),
                ),
              ),
            ),
            FeatureCard(
              title: 'Worksheet Creator',
              icon: Icons.assignment,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WorksheetCreatorScreen(),
                ),
              ),
            ),
            FeatureCard(
              title: 'Visual Aids',
              icon: Icons.draw,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VisualAidScreen(),
                ),
              ),
            ),
            FeatureCard(
              title: 'Educational Games',
              icon: Icons.games,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GameGeneratorScreen(),
                ),
              ),
            ),
            FeatureCard(
              title: 'Lesson Plans',
              icon: Icons.calendar_today,
              color: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LessonPlanScreen(),
                ),
              ),
            ),
            FeatureCard(
              title: 'Student Progress',
              icon: Icons.trending_up,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StudentProgressScreen(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawer(BuildContext context, AuthService auth) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  child: Icon(Icons.person, size: 40),
                ),
                const SizedBox(height: 10),
                Text(
                  auth.userProfile?['name'] ?? 'Teacher',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  auth.userProfile?['school'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('Community Library'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityLibraryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.assessment),
            title: const Text('Reports'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to reports
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              // Show help
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }
}