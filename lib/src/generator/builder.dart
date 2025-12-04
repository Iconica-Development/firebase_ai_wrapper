import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'ai_function_generator.dart';

Builder aiFunctionBuilder(BuilderOptions options) {
  return PartBuilder([AIFunctionGenerator()], '.ai.dart');
}
