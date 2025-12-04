import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class AIFunctionGenerator extends Generator {
  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();
    bool hasGeneratedFunctions = false;
    final List<String> registrationFunctions = [];

    // Check all top-level classes in the library
    for (final element in library.allElements) {
      if (element is ClassElement) {
        // Check if class has @AIToolbox annotation
        ElementAnnotation? toolboxAnnotation;
        for (final annotation in element.metadata.annotations) {
          final annotationType = annotation.computeConstantValue()?.type;
          if (annotationType?.getDisplayString() == 'AIToolbox') {
            toolboxAnnotation = annotation;
            break;
          }
        }

        // Process methods in this class
        bool hasAIToolboxAnnotation = toolboxAnnotation != null;

        // Check all methods in the class
        for (final method in element.methods) {
          final methodName = method.name;

          if (methodName?.isEmpty ?? true) continue;

          // Check if method should be skipped or has annotations
          bool shouldSkip = false;
          ElementAnnotation? functionAnnotation;

          // Check for method-level annotations
          for (final annotation in method.metadata.annotations) {
            final annotationType = annotation.computeConstantValue()?.type;
            final typeName = annotationType?.getDisplayString();

            if (typeName == 'NotAI') {
              shouldSkip = true;
              break;
            } else if (typeName == 'AIFunction') {
              functionAnnotation = annotation;
            }
          }

          // Skip private methods and marked methods
          if (shouldSkip || (methodName?.startsWith('_') ?? false)) {
            continue;
          }

          // Only process methods if class has @AIToolbox or method has @AIFunction
          if (!hasAIToolboxAnnotation && functionAnnotation == null) {
            continue;
          }

          hasGeneratedFunctions = true;

          // Extract description and parameters
          String description = 'AI Function $methodName';
          Map<String, Map<String, String>> parameters = {};

          // Try to get dartdoc comment first
          final dartdoc = method.documentationComment;
          if (dartdoc != null && dartdoc.isNotEmpty) {
            // Clean up the dartdoc comment and separate description from @param tags
            final lines = dartdoc
                .split('\n')
                .map((line) => line.replaceFirst(RegExp(r'^\s*///?\s?'), ''))
                .where((line) => line.isNotEmpty)
                .toList();

            // Extract only the description part (before any @param tags)
            final descriptionLines = <String>[];
            for (final line in lines) {
              if (line.startsWith('@param') || line.startsWith('* @param')) {
                break; // Stop at first @param tag
              }
              descriptionLines.add(line);
            }

            if (descriptionLines.isNotEmpty) {
              description = descriptionLines.join(' ').trim();
            }
          }

          if (functionAnnotation != null) {
            // Method has @AIFunction annotation - use its parameters
            final annotationValue = functionAnnotation.computeConstantValue();
            if (annotationValue != null) {
              final descField = annotationValue.getField('description');
              if (descField != null && !descField.isNull) {
                // Override with annotation description if provided
                description = descField.toStringValue() ?? description;
              }

              final parametersMap =
                  annotationValue.getField('parameters')?.toMapValue() ?? {};
              for (final entry in parametersMap.entries) {
                final key = entry.key?.toStringValue();
                final value = entry.value?.toStringValue();
                if (key != null && value != null) {
                  parameters[key] = {'type': 'String', 'description': value};
                }
              }
            }
          } else if (hasAIToolboxAnnotation) {
            // Class has @AIToolbox - infer parameters from method signature
            for (final param in method.formalParameters) {
              final paramName = param.name;
              final paramType = param.type.getDisplayString();
              if (paramName == null) continue;

              // Try to extract parameter description from dartdoc
              String paramDescription = 'Parameter of type $paramType';
              if (dartdoc != null && dartdoc.isNotEmpty) {
                // Look for @param or [paramName] in dartdoc
                final lines = dartdoc.split('\n');
                for (final line in lines) {
                  final cleanLine = line.replaceFirst(
                    RegExp(r'^\s*///?\s?'),
                    '',
                  );
                  if (cleanLine.startsWith('@param $paramName') ||
                      cleanLine.startsWith('* @param $paramName')) {
                    paramDescription = cleanLine
                        .replaceFirst(
                          RegExp(
                            r'^(\*\s*)?@param\s+' +
                                RegExp.escape(paramName) +
                                r'\s+',
                          ),
                          '',
                        )
                        .trim();
                    break;
                  } else if (cleanLine.contains('[$paramName]')) {
                    // Look for [paramName]: description pattern
                    final match = RegExp(
                      r'\[$paramName\]\s*:?\s*(.+)',
                    ).firstMatch(cleanLine);
                    if (match != null) {
                      paramDescription =
                          match.group(1)?.trim() ?? paramDescription;
                      break;
                    }
                  }
                }
              }

              parameters[paramName] = {
                'type': paramType,
                'description': paramDescription,
              };
            }

            // Try to get description from class annotation
            final classAnnotationValue = toolboxAnnotation
                .computeConstantValue();
            if (classAnnotationValue != null) {
              final descField = classAnnotationValue.getField('description');
              if (descField != null && !descField.isNull) {
                final classDesc = descField.toStringValue();
                if (classDesc != null && classDesc.isNotEmpty) {
                  description = '$classDesc - $methodName';
                }
              }
            }
          }

          // Generate the function declaration
          buffer.writeln('// Generated code for ${element.name}.$methodName');
          buffer.writeln(
            'final ${methodName}Declaration = FunctionDeclaration(',
          );
          buffer.writeln('  "$methodName",');
          buffer.writeln('  "$description",');
          buffer.writeln('  parameters: <String, Schema>{');

          // Generate parameter schemas
          for (final paramEntry in parameters.entries) {
            final paramName = paramEntry.key;
            final paramInfo = paramEntry.value;
            final paramType = paramInfo['type'] ?? 'String';
            final paramDescription = paramInfo['description'] ?? 'Parameter';

            // Convert Dart types to Schema types
            String schemaCall;
            switch (paramType) {
              case 'int':
              case 'int?':
                schemaCall = 'Schema.integer(description: "$paramDescription")';
                break;
              case 'double':
              case 'double?':
              case 'num':
              case 'num?':
                schemaCall = 'Schema.number(description: "$paramDescription")';
                break;
              case 'bool':
              case 'bool?':
                schemaCall = 'Schema.boolean(description: "$paramDescription")';
                break;
              case 'List<String>':
              case 'List<String>?':
                schemaCall =
                    'Schema.array(items: Schema.string(), description: "$paramDescription")';
                break;
              case 'List<int>':
              case 'List<int>?':
                schemaCall =
                    'Schema.array(items: Schema.integer(), description: "$paramDescription")';
                break;
              case 'List<double>':
              case 'List<double>?':
              case 'List<num>':
              case 'List<num>?':
                schemaCall =
                    'Schema.array(items: Schema.number(), description: "$paramDescription")';
                break;
              default:
                schemaCall = 'Schema.string(description: "$paramDescription")';
                break;
            }

            buffer.writeln('    "$paramName": $schemaCall,');
          }

          buffer.writeln('  },');
          buffer.writeln(');');
          buffer.writeln();

          // Generate function signature string for system prompts
          final paramSignatures = <String>[];
          for (final paramEntry in parameters.entries) {
            final paramName = paramEntry.key;
            final paramInfo = paramEntry.value;
            final paramType = paramInfo['type'] ?? 'String';

            // Convert Dart types to readable types
            String readableType;
            switch (paramType) {
              case 'int':
              case 'int?':
                readableType = 'int';
                break;
              case 'double':
              case 'double?':
              case 'num':
              case 'num?':
                readableType = 'number';
                break;
              case 'bool':
              case 'bool?':
                readableType = 'boolean';
                break;
              case 'List<String>':
              case 'List<String>?':
                readableType = 'List<String>';
                break;
              case 'List<int>':
              case 'List<int>?':
                readableType = 'List<int>';
                break;
              case 'List<double>':
              case 'List<double>?':
                readableType = 'List<number>';
                break;
              default:
                readableType = 'String';
                break;
            }

            paramSignatures.add('$paramName: $readableType');
          }

          final functionSignature =
              '`$methodName(${paramSignatures.join(', ')})`: $description';

          buffer.writeln('// Function signature for system prompts');
          buffer.writeln(
            'const String ${methodName}Signature = r"""$functionSignature""";',
          );
          buffer.writeln();

          // Create function wrapper for registration
          buffer.writeln('// Function wrapper for $methodName');
          if (method.isStatic) {
            buffer.writeln(
              'Function get _${methodName}Function => ${element.name}.$methodName;',
            );
          } else {
            buffer.writeln(
              'Function get _${methodName}Function => (Map<String, dynamic> args) {',
            );
            buffer.writeln('  final className = ${element.name}.instance;');

            // Generate the method call with proper argument mapping
            final paramNames = method.formalParameters
                .map((param) => param.name)
                .where((name) => name != null)
                .toList();

            if (paramNames.isEmpty) {
              buffer.writeln('  return className.$methodName();');
            } else {
              final argsList = paramNames
                  .map((name) => 'args["$name"]')
                  .join(', ');
              buffer.writeln('  return className.$methodName($argsList);');
            }
            buffer.writeln('};');
          }
          buffer.writeln();

          // Add to the static registry map
          registrationFunctions.add(methodName!);
        }
      }
    }

    if (!hasGeneratedFunctions) {
      return '';
    }

    // Generated function list for auto-registration
    buffer.writeln(
      'List<(FunctionDeclaration, Function)> get _generatedFunctionList => [',
    );
    for (final funcName in registrationFunctions) {
      buffer.writeln('  (${funcName}Declaration, _${funcName}Function),');
    }
    buffer.writeln('];');
    buffer.writeln();

    // Generate combined system prompt with all function signatures
    buffer.writeln('// Combined function signatures for system prompts');
    buffer.writeln('String get generatedFunctionSignatures => [');
    for (final funcName in registrationFunctions) {
      buffer.writeln('  ${funcName}Signature,');
    }
    buffer.writeln('].join("\\n");');
    buffer.writeln();
    buffer.writeln('extension AutoGeneratedFunctions on FirebaseAIWrapper {');
    buffer.writeln(
      '  /// Auto-register functions with system info that includes function signatures',
    );
    buffer.writeln('  FirebaseAIWrapper auto(String systemInfo) {');
    buffer.writeln(
      '    final systemInfoWithFunctions = systemInfo + "\\n\\nAvailable functions:\\n" + generatedFunctionSignatures;',
    );
    buffer.writeln(
      '    FirebaseAIWrapper.instance.registerGeneratedFunctions(_generatedFunctionList, systemInfoWithFunctions);',
    );
    buffer.writeln('    return FirebaseAIWrapper.instance;');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();

    return buffer.toString();
  }
}
