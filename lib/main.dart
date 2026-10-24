import 'package:flutter/material.dart';

import 'menu_page.dart';
import 'repo.dart';
import 'sync.dart';
import 'tally_page.dart';
import 'utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Repo.i.init();
  Repo.i.onChanged = () => SyncService.i.schedule();
  runApp(const HisabKhataApp());
  // ক্লাউড চালু করা অ্যাপ খোলার পর ব্যাকগ্রাউন্ডে হয়, তাই অফলাইনে অ্যাপ আটকায় না।
  SyncService.i.init();
}

class HisabKhataApp extends StatelessWidget {
  const HisabKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'হিসাব খাতা',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kRed, primary: kRed),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [TallyPage(), MenuPage()],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: kPink,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book, color: kRed),
            label: 'টালি',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            label: 'মেনু',
          ),
        ],
      ),
    );
  }
}
