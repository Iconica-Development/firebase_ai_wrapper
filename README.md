# Firebase AI Wrapper

A powerful Flutter package that automatically generates Firebase AI function declarations from annotated classes using code generation. Write your functions once with simple annotations and dartdoc comments, and let the generator handle the AI integration boilerplate.

## Features

- **Auto-generated function declarations** from annotated classes
- **Dartdoc integration** - uses your documentation comments for AI descriptions
- **Static and instance method support** 
- **Type-safe parameter handling** with automatic type conversion
- **System prompt generation** with function signatures
- **Zero boilerplate** - just add annotations and run build_runner

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_ai_wrapper: ^1.0.0
  firebase_ai: ^0.2.3
  
dev_dependencies:
  build_runner: ^2.4.7
```

## Quick Start

### 1. Annotate your class

```dart
import 'package:firebase_ai_wrapper/firebase_ai_wrapper.dart';

@AIToolbox()
class CoffeeShop {
  /// Add a specific ingredient to the coffee
  /// @param ingredient The ingredient to add (e.g., "espresso", "milk", "sugar")  
  /// @param amount The amount to add (e.g., "1 shot", "200ml", "2 teaspoons")
  void addIngredient(String ingredient, String amount) {
    print('Adding $amount of $ingredient');
  }

  /// Set the temperature of the coffee
  /// @param temperature The desired temperature (60 for warm, 80 for hot)
  static void setTemperature(int temperature) {
    print('Setting temperature to $temperature°C');
  }

  /// Process a list of ingredients
  /// @param ingredients List of ingredients to process
  void processIngredients(List<String> ingredients) {
    for (final ingredient in ingredients) {
      print('Processing: $ingredient');
    }
  }

  @NotAI()
  void _privateHelper() {
    // This method won't be exposed to AI
  }
}
```

### 2. Generate the code

```bash
dart run build_runner build
```

### 3. Use with Firebase AI

```dart
void main() async {
  await Firebase.initializeApp();
  
  // Auto-register all generated functions
  final wrapper = FirebaseAIWrapper.instance.auto(<Add system context here>);
  
  // The AI can now call your functions!
  final results = await wrapper.action("Add 2 shots of espresso and set temperature to 75 degrees");
}
```

### Manual Usage (Without Code Generation)

You can also use the wrapper manually without annotations or code generation:

```dart
void main() async {
  await Firebase.initializeApp();
  
  const systemInfo = """You are a helpful assistant.
  Available functions will be registered programmatically.""";
  
  // Initialize with empty functions list and systemInfo
  // Or
  // Define your List<(FunctionDeclaration, Function)> and pass it here for manual configuration
  // Each item needs, a FunctionDeclaration and a Function themselves
  FirebaseAIWrapper.instance.registerGeneratedFunctions([], systemInfo);
  final wrapper = FirebaseAIWrapper.instance;
  
  // Use the wrapper for AI chat without function calling
  final results = await wrapper.action("Hello, how can you help me?");
}
```

## Annotations

### @AIToolbox()
Mark a class to automatically expose all public methods to AI:

```dart
@AIToolbox()
class MyFunctions {
  void publicMethod() {} // ✅ Exposed to AI
  void _privateMethod() {} // ❌ Not exposed (starts with _)
  
  @NotAI()
  void skippedMethod() {} // ❌ Not exposed (marked with @NotAI)
}
```

### @AIFunction()
Manually configure individual methods:

```dart
class MyClass {
  @AIFunction('Custom description', parameters: {
    'param1': 'Description for param1',
    'param2': 'Description for param2'
  })
  void myMethod(String param1, int param2) {}
}
```

### @NotAI()
Skip methods in an @AIToolbox class:

```dart
@AIToolbox()
class MyFunctions {
  void aiMethod() {} // ✅ Exposed
  
  @NotAI()
  void utilityMethod() {} // ❌ Not exposed
}
```

## Documentation Integration

The generator extracts descriptions from your dartdoc comments:

```dart
/// This method calculates shipping cost
/// @param weight Package weight in kg
/// @param distance Distance in km  
double calculateShipping(double weight, int distance) {
  return weight * distance * 0.1;
}
```

Generates function signature:
```
`calculateShipping(weight: number, distance: int)`: This method calculates shipping cost
```

## Supported Types

The generator supports automatic type conversion:

| Dart Type | AI Schema | Function Signature |
|-----------|-----------|-------------------|
| `String` | `Schema.string()` | `String` |
| `int` | `Schema.integer()` | `int` |
| `double` | `Schema.number()` | `number` |
| `bool` | `Schema.boolean()` | `boolean` |
| `List<String>` | `Schema.array(items: Schema.string())` | `List<String>` |
| `List<int>` | `Schema.array(items: Schema.integer())` | `List<int>` |

## Extension Methods

### Auto-discovery
```dart
// Automatically register all generated functions with injected function signatures
final wrapper = FirebaseAIWrapper.instance.auto(<Add system context here>);
```

## Generated Output

For each annotated method, the generator creates:

1. **Function Declaration** - Firebase AI compatible schema
2. **Function Signature** - Human-readable string for system prompts  
3. **Auto-registration** - Automatic registration using extension method
4. **Type-safe wrappers** - Handles static/instance methods

Example generated code:
```dart
// Generated function declaration
final addIngredientDeclaration = FunctionDeclaration(
  "addIngredient",
  "Add a specific ingredient to the coffee",
  parameters: <String, Schema>{
    "ingredient": Schema.string(description: "The ingredient to add"),
    "amount": Schema.string(description: "The amount to add"),
  },
);

// Generated function signature for system prompts
const String addIngredientSignature = r"""`addIngredient(ingredient: String, amount: String)`: Add a specific ingredient to the coffee""";
```

## Examples

Check out the [example](example/) directory for a small example

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

See the [LICENSE](LICENSE) file for details.
