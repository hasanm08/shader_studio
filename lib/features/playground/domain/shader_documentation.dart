/// One short explanation shown next to a shader's source.
///
/// These notes describe a section of the real `.frag` file. They are not a
/// second copy of the shader source. The code panel loads that source from
/// the asset bundle.
class CodeNote {
  /// Creates a note titled [title].
  const CodeNote({required this.title, required this.body});

  /// Section title, usually a function or uniform name.
  final String title;

  /// Why that section exists.
  final String body;
}
