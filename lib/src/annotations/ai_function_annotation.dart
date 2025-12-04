// Annotation for marking functions that should be available to AI
class AIFunction {
  const AIFunction(this.description, {this.parameters = const {}});

  final String description;
  final Map<String, String> parameters;
}

// Annotation for marking a class as an AI toolbox - all public methods will be generated
class AIToolbox {
  const AIToolbox();
}

// Annotation for skipping methods in an AIToolbox class
class NotAI {
  const NotAI();
}
