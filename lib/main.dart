import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:thinkcode/provider/batch_provider.dart';
import 'package:thinkcode/provider/income_expense_provider.dart';
import 'package:thinkcode/provider/manage_batch_provider.dart';
import 'package:thinkcode/provider/selected_batch_provider.dart';
import 'package:thinkcode/provider/signup_provider.dart' ;
import 'package:thinkcode/provider/student_provider.dart';
import 'package:thinkcode/provider/mark_student_paid.dart';
import 'package:thinkcode/provider/student_filter_provider.dart';
import 'package:thinkcode/provider/subject_provider.dart';
import 'package:thinkcode/screens/add_student_screen.dart';
import 'package:thinkcode/screens/all_students_screen.dart';
import 'package:thinkcode/screens/batch_screen.dart';
import 'package:thinkcode/screens/expense_screen.dart';
import 'package:thinkcode/screens/hrm_homescreen.dart';
import 'package:thinkcode/screens/hrm_info_screen.dart';
import 'package:thinkcode/screens/login_sceen.dart';
import 'package:thinkcode/screens/manage_batch_screen.dart';
import 'package:thinkcode/screens/mark_fee_screen.dart';
import 'package:thinkcode/screens/splash_screen.dart';
import 'package:thinkcode/screens/subject_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ThinkCodeHRMApp());
}

class ThinkCodeHRMApp extends StatelessWidget {
  const ThinkCodeHRMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider2()),
        ChangeNotifierProvider(create: (_) => MarkStudentPaidProvider()),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => SubjectProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
        ChangeNotifierProvider(create: (_) => SelectedBatchProvider()),
        ChangeNotifierProvider(create: (_) => IncomeExpenseProvider()),
        ChangeNotifierProvider(create: (_) => StudentFilterProvider()),
        ChangeNotifierProvider(create: (_) => ManageBatchProvider(batchProvider: BatchProvider(), subjectProvider: SubjectProvider())),

      ],
      child: MaterialApp(
        title: 'ThinkCode HRM',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: SplashScreen(),
        debugShowCheckedModeBanner: false,

        initialRoute: '/splashscreen',
        routes: {
          '/home': (_) => HRMHomeScreen(),
          '/splashscreen': (_) => SplashScreen(),
          '/subjects': (_) =>  SubjectScreen(),
          '/batches': (_) =>  BatchScreen(),
          '/login': (_) =>  LoginScreen(),
          '/add-student': (_) =>  AddStudentScreen(),
          '/allstudents': (_) =>  AllStudentsScreen(),
          '/hrminfo': (_) =>  HRMInfoScreen(),
          '/feemarkscreen': (_) =>  MarkStudentPaidScreen(),
          '/expensescreen': (_) =>  IncomeExpenseScreen(),
          '/managebatchscreen': (_) =>  ManageBatchScreen(),
        },
      ),
    );
  }
}
