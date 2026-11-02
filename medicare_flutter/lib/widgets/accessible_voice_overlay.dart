import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_controller.dart';

/// Wraps the application to support screen double-tap accessibility gesture
/// without displaying any floating buttons or overlay banners on screen.
class AccessibleVoiceOverlay extends StatelessWidget {
  final Widget child;
  const AccessibleVoiceOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final voice = Provider.of<VoiceController>(context, listen: false);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () {
          voice.toggleContinuousListening();
        },
        child: child,
      ),
    );
  }
}
