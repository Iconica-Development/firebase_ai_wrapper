# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2024-12-04

### Added
- **Initial release** of Firebase AI Wrapper
- **Code generation** from `@AIToolbox()` annotated classes
- **Dartdoc integration** - automatically extracts function descriptions and parameter docs
- **Static and instance method support** with automatic wrapper generation
- **Type-safe parameter handling** with automatic type conversion
- **System prompt generation** with human-readable function signatures
- **Auto-registration system** - zero boilerplate setup
- **Extension methods** for easy wrapper configuration

### Features
- **Annotations**:
  - `@AIToolbox()` - Mark classes for automatic function exposure
  - `@AIFunction()` - Manual configuration of individual methods
  - `@NotAI()` - Skip methods in AIToolbox classes

- **Type Support**:
  - Basic types: `String`, `int`, `double`, `bool`
  - Nullable types: `String?`, `int?`, `double?`, `bool?`
  - List types: `List<String>`, `List<int>`, `List<double>`
  - Automatic Schema generation for Firebase AI

- **Documentation**:
  - Extracts method descriptions from dartdoc comments
  - Parses `@param` tags for parameter descriptions
  - Generates clean function signatures for system prompts

- **Auto-discovery**:
  - Automatic function registration on `.auto()`
  - Extension methods: `.auto()`
  - No manual wiring required

- **Manual Usage**:
  - Can be used without code generation or annotations
  - Direct initialization with `registerGeneratedFunctions([], systemInfo)`
  - Supports pure AI chat without function calling

### Technical Details
- Uses `.ai.dart` file extension to avoid conflicts with other generators and because it is funny
- Supports both static and instance methods
- Handles method overloading and optional parameters
- Integrates with `build_runner` for code generation
- Compatible with Firebase AI 0.2.3+
