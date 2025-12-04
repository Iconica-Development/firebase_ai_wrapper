import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class FirebaseAIWrapper {
  FirebaseAIWrapper._internal();

  GenerativeModel? _model;
  ChatSession? _chat;

  final Map<String, FunctionDeclaration> _functionDeclarations = {};
  final Map<String, Function> _functionMap = {};

  static FirebaseAIWrapper? _instance;
  static FirebaseAIWrapper get instance {
    _instance ??= FirebaseAIWrapper._internal();
    return _instance!;
  }

  void _init(String systemInfo) {
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash',
      systemInstruction: Content.system(systemInfo),
      tools: _functionDeclarations.isNotEmpty
          ? [Tool.functionDeclarations(_functionDeclarations.values.toList())]
          : null,
    );
  }

  Future<List<dynamic>?> action(String prompt) async {
    if (_model == null) {
      throw Exception(
        'FirebaseAIWrapper is not initialized. Make sure to use annotated functions, and run the code generator. OR initialize yourself with registerGeneratedFunctions().',
      );
    }

    _chat ??= _model!.startChat();

    var response = await _chat!.sendMessage(Content.text(prompt));

    debugPrint(response.text);

    if (response.functionCalls.isEmpty) {
      return null;
    }

    var functionResponses = <FunctionResponse>[];
    var logicalResponses = <dynamic>[];
    for (final functionCall in response.functionCalls) {
      var functionResponse = _callFunction(
        functionCall.name,
        functionCall.args,
      );
      var chatResponse = FunctionResponse(functionCall.name, functionResponse);

      logicalResponses.add(functionResponse);
      functionResponses.add(chatResponse);
    }

    var functionCalls = Content.functionResponses(functionResponses);

    var resp = await _chat!.sendMessage(functionCalls);

    if (resp.text != null && resp.text!.isNotEmpty) {
      debugPrint(resp.text);
    }

    return logicalResponses;
  }

  Map<String, dynamic> _callFunction(
    String functionName,
    Map<String, dynamic> args,
  ) {
    final function = _functionMap[functionName];
    if (function == null) {
      return {
        'success': false,
        'reason': 'Unsupported function call $functionName',
      };
    }

    // Check if it's a wrapper function that takes a Map (for instance methods)
    if (function is Function(Map<String, dynamic>)) {
      var result = function(args);
      return {'success': true, 'result': result};
    } else {
      var result = Function.apply(function, args.values.toList());
      return {'success': true, 'result': result};
    }
  }

  void registerGeneratedFunctions(
    List<(FunctionDeclaration, Function)> functions,
    String systemInfo,
  ) {
    for (final item in functions) {
      _functionDeclarations[item.$1.name] = item.$1;
      _functionMap[item.$1.name] = item.$2;
    }

    _init(systemInfo);
  }
}
