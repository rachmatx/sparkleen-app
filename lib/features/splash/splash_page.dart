import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_assets.dart';
import '../../core/widgets/app_artwork.dart';

/// The startup router keeps this animation visible for at least two seconds.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.value = 1;
    } else if (_motion.status == AnimationStatus.dismissed) {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF125CDA),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _motion,
                    builder: (context, child) {
                      final enter = Curves.easeOutCubic.transform(
                        (_motion.value / .25).clamp(0.0, 1.0),
                      );
                      final lift = _motion.value > .25
                          ? (1 -
                                    ((_motion.value - .625).abs() / .375).clamp(
                                      0.0,
                                      1.0,
                                    )) *
                                8
                          : 0.0;
                      return Opacity(
                        opacity: enter,
                        child: Transform.translate(
                          offset: Offset(0, (1 - enter) * 14 - lift),
                          child: child,
                        ),
                      );
                    },
                    child: const AppArtwork(
                      asset: AppAssets.splash,
                      height: 220,
                      width: 300,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'sparkleen',
                    style: Theme.of(context).textTheme.headlineLarge
                        ?.copyWith(color: Colors.white, fontSize: 34),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Laundry jadi ringan',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: 140,
                    child: LinearProgressIndicator(
                      value: reduced ? 1 : null,
                      minHeight: 3,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Menyiapkan aplikasi',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
