import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/library/view/library_screen.dart';
import 'features/reader/cubit/reader_cubit.dart';
import 'features/reader/cubit/reader_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Hive-ийг эхлүүлэх
  await Hive.initFlutter();

  // 2. Тохиргооны хайрцаг нээх
  final settingsBox = await Hive.openBox('settingsBox');

  runApp(MyApp(settingsBox: settingsBox));
}

class MyApp extends StatelessWidget {
  final Box? settingsBox;
  const MyApp({super.key, this.settingsBox});

  @override
  Widget build(BuildContext context) {
    if (settingsBox == null) {
      return const MaterialApp(
        title: 'Kindle App',
        debugShowCheckedModeBanner: false,
        home: CounterHomePage(),
      );
    }

    return BlocProvider(
      create: (_) => ReaderCubit(settingsBox!),
      child: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (context, state) {
          // Төлөвөөс хамаарч үндсэн Theme сонгох
          ThemeData currentTheme;
          switch (state.themeMode) {
            case ReaderThemeMode.sepia:
              currentTheme = AppTheme.sepiaTheme;
              break;
            case ReaderThemeMode.light:
              currentTheme = AppTheme.lightTheme;
              break;
            case ReaderThemeMode.dark:
              currentTheme = AppTheme.darkTheme;
              break;
          }

          return MaterialApp(
            title: 'Kindle App',
            debugShowCheckedModeBanner: false,
            theme: currentTheme,
            home: const LibraryScreen(),
          );
        },
      ),
    );
  }
}

class CounterHomePage extends StatefulWidget {
  const CounterHomePage({super.key});

  @override
  State<CounterHomePage> createState() => _CounterHomePageState();
}

class _CounterHomePageState extends State<CounterHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Demo Home Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}