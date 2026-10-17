import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shader_studio/app/routing/app_router.dart';
import 'package:shader_studio/app/shader_studio_scope.dart';
import 'package:shader_studio/app/theme/app_theme.dart';
import 'package:shader_studio/core/rendering/shader_loader.dart';

/// Root widget. Owns the shader loader for the process.
///
/// [loader] is optional so tests can substitute a program loader. The
/// default calls `FragmentProgram.fromAsset`.
class ShaderStudioApp extends StatefulWidget {
  /// Creates the application.
  const ShaderStudioApp({super.key, this.loader});

  /// Loader shared with every canvas. Null uses the real asset loader.
  final ShaderLoader? loader;

  @override
  State<ShaderStudioApp> createState() => _ShaderStudioAppState();
}

class _ShaderStudioAppState extends State<ShaderStudioApp> {
  late final ShaderLoader _loader = widget.loader ?? ShaderLoader();

  @override
  Widget build(BuildContext context) {
    return ShaderStudioScope(
      loader: _loader,
      child: MaterialApp(
        title: 'Shader Studio',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          dragDevices: <PointerDeviceKind>{
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
          },
        ),
        onGenerateRoute: AppRouter.onGenerate,
        initialRoute: AppRouter.gallery,
      ),
    );
  }
}
