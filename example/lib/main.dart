import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai_wrapper/firebase_ai_wrapper.dart';
import 'package:firebase_ai/firebase_ai.dart';

part 'main.ai.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with minimal config for example
  await Firebase.initializeApp(
    // Setup with your own Firebase project settings
    options: FirebaseOptions(
      apiKey: 'your_api_key',
      appId: 'your_app_id',
      messagingSenderId: 'your_messaging_sender_id',
      projectId: 'your_project_id',
      authDomain: 'your_auth_domain',
      storageBucket: 'your_storage_bucket',
      measurementId: 'your_measurement_id',
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase AI Wrapper Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  String output = 'Click the button to test AI functions';
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Firebase AI Wrapper Example'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Example AI Toolbox Demo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  output,
                  style: TextStyle(fontFamily: 'monospace'),
                ),
              ),
              SizedBox(height: 20),
              if (isLoading)
                CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: () => testAIFunctions(),
                  child: Text('Test AI Functions'),
                ),
              SizedBox(height: 20),
              Text(
                'This example shows how @AIToolbox annotation automatically\ngenerates AI functions from your class methods.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> testAIFunctions() async {
    setState(() {
      isLoading = true;
      output = 'Testing AI functions...';
    });

    try {
      // IMPORTANT: THIS IS A SIMPLIFIED EXAMPLE.
      // THIS IS THE MOST IMPORTANT PIECE TO GET RIGHT FOR YOUR USE CASE.
      // AND MAY REQUIRE CUSTOMIZATION BASED ON YOUR FUNCTION SIGNATURES AND INTENDED BEHAVIOR.
      // CAN BE LOADED FROM A ASSETS.MD FILE OR DEFINED ELSEWHERE.
      const systemInfo = """You are a helpful utility assistant.
          MAKE SURE TO WHEN FUNCTION CALLS ARE MADE TO USE THE CORRECT FUNCTION SIGNATURES PROVIDED IN THE SYSTEM INFO.

          If a function is not avaible, respond with "To do that I need a function that does X"
          e.g.
          U: Calculate the product of two numbers
          A: To do that I need function multiplyNumbers(x: int, y: int) which multiplies two numbers and returns the result.
          """;

      final wrapper = FirebaseAIWrapper.instance.auto(systemInfo);

      var result = await wrapper.action('Calculate the sum of 6 17');
      setState(() {
        output = 'Result: $result';
      });

      var greetResult =
          await wrapper.action('Greet the user named Alice with excitement');
      setState(() {
        output += '\n$greetResult';
      });

      var processResult = await wrapper
          .action('Process the list of items: apple, banana, cherry');

      setState(() {
        output += '\n$processResult';
      });

      // Simulate AI function calls
      setState(() {
        output += '\nAll functions work correctly! ✅';
      });
    } catch (e) {
      setState(() {
        output = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

/// Example AI Toolbox - all methods will be automatically converted to AI functions
@AIToolbox()
class ExampleFunctions {
  /// Calculate the sum of two numbers
  /// @param a First number to add
  /// @param b Second number to add
  static int calculateSum(int a, int b) {
    return a + b;
  }

  /// Greet a user with their name
  /// @param name The user's name
  /// @param isExcited Whether to use excited tone
  static void greetUser(String name, bool isExcited) {
    final greeting = isExcited ? 'Hello there, $name! 🎉' : 'Hello, $name.';
    debugPrint(greeting);
  }

  /// Process a list of items (demonstrates list parameter)
  /// @param items List of items to process
  static void processItems(List<dynamic> items) {
    debugPrint('Processing ${items.length} items: ${items.join(', ')}');
  }

  /// This method will be skipped from AI generation
  @NotAI()
  static void internalMethod() {
    debugPrint('This method is not exposed to AI');
  }
}
