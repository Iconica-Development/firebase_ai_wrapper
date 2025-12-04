# Firebase AI Wrapper Example

This is a minimal example app demonstrating how to use the `firebase_ai_wrapper` package.

## Features Demonstrated

- **@AIToolbox annotation**: Automatically converts class methods to AI-callable functions
- **Type inference**: Automatically detects parameter types (int, String, bool, List<String>)
- **@NotAI annotation**: Skip specific methods from AI generation
- **Auto-registration**: Functions are automatically registered with FirebaseAIWrapper

## Running the Example

1. Get dependencies:
   ```bash
   flutter pub get
   ```

2. Generate the AI function code:
   ```bash
   dart run build_runner build
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Key Files

- `lib/main.dart` - Main app with @AIToolbox class
- `lib/main.ai.dart` - Generated AI function definitions (created by build_runner)

## How It Works

1. Annotate a class with `@AIToolbox()`
2. Add methods with dartdoc comments describing parameters
3. Run `dart run build_runner build`
4. Use `FirebaseAIWrapper.instance.auto()` to register all generated functions
5. Functions are now callable by AI with proper type checking