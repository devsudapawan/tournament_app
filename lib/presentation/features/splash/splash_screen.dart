import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../common/providers/providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fade  = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.6)),
    );
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _ctrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    final user = ref.read(authStateProvider).value;
    context.go(user != null ? AppRoutes.shell : AppRoutes.login);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: Center(
      child: FadeTransition(
        opacity: _fade,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(
                  'PC',
                  style: AppTextStyles.display(
                    size: 32, color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('POINTCALC', style: AppTextStyles.display(size: 28)),
              const SizedBox(height: 8),
              Text(
                'Automate your tournament',
                style: AppTextStyles.body(color: AppColors.muted),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.yellow.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
