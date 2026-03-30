class TextCleaner {
  /// Master method — runs all fixes in the right order
  static String clean(String rawText) {
    if (rawText.trim().isEmpty) return rawText;

    String text = rawText;

    text = _fixRunTogetherWords(text); // "withThe" → "with The"
    text = _fixLineBreaks(text); // Smart paragraph detection
    text = _fixSpacing(text); // Double spaces, trailing spaces
    text = _fixPunctuation(text); // Space before . , ! ?
    text = _fixCapitalization(text); // Sentence-start capitals

    return text.trim();
  }

  /// Fix words that got concatenated: "withThe" → "with The"
  /// ML Kit sometimes merges adjacent words when they're close together.
  /// This uses a regex to find lowercase→uppercase transitions
  /// that indicate a word boundary was missed.
  static String _fixRunTogetherWords(String text) {
    // Pattern: lowercase letter immediately followed by uppercase letter
    // e.g. "withThe" → "with The", "helloWorld" → "hello World"
    return text.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }

  /// Fix line breaks:
  /// - Single newlines inside a paragraph → space (they're just word-wrap)
  /// - Double newlines → keep as paragraph break
  /// - Excessive newlines (3+) → reduce to 2
  static String _fixLineBreaks(String text) {
    // Preserve intentional double line breaks (paragraph gaps)
    // by temporarily replacing them with a placeholder
    text = text.replaceAll(RegExp(r'\n{2,}'), '¶');

    // Single line breaks that split mid-sentence → join with a space
    // But only if the next line starts with a lowercase letter
    // (indicating it's a continuation, not a new sentence/heading)
    text = text.replaceAllMapped(
      RegExp(r'\n(?=[a-z,;:])'),
      (match) => ' ',
    );

    // Single line breaks before uppercase = likely a new sentence,
    // keep the break but ensure single newline
    text = text.replaceAll('\n', '\n');

    // Restore paragraph breaks
    text = text.replaceAll('¶', '\n\n');

    // Clean up 3+ newlines → max 2
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text;
  }

  /// Fix spacing issues
  static String _fixSpacing(String text) {
    // Multiple spaces → single space
    text = text.replaceAll(RegExp(r' {2,}'), ' ');

    // Remove spaces at the start of each line
    text = text.replaceAll(RegExp(r'^ +', multiLine: true), '');

    // Remove trailing spaces at end of each line
    text = text.replaceAll(RegExp(r' +$', multiLine: true), '');

    return text;
  }

  /// Fix punctuation spacing:
  /// Remove space before . , ! ? ; : → "Hello ." becomes "Hello."
  /// Add space after . , ! ? if missing → "Hello.World" → "Hello. World"
  static String _fixPunctuation(String text) {
    // Remove space before punctuation
    text = text.replaceAll(RegExp(r' ([.,!?;:])'), r'\1');

    // Add space after punctuation if followed by a letter/digit
    text = text.replaceAllMapped(
      RegExp(r'([.!?])([A-Za-z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return text;
  }

  /// Capitalize the first letter after sentence-ending punctuation
  static String _fixCapitalization(String text) {
    // Capitalize first character of entire text
    if (text.isNotEmpty) {
      text = text[0].toUpperCase() + text.substring(1);
    }

    // Capitalize first letter after ". ", "! ", "? "
    text = text.replaceAllMapped(
      RegExp(r'([.!?]\s+)([a-z])'),
      (match) => '${match.group(1)}${match.group(2)!.toUpperCase()}',
    );

    return text;
  }
}
