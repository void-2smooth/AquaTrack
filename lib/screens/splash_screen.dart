import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// Splash screen shown on app startup
/// 
/// Displays personalized greeting and loading animation
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _particleAnimation;
  
  String _statusText = 'Getting things ready...';
  int _statusIndex = 0;
  Timer? _statusTimer;
  
  final List<String> _statusMessages = [
    'Getting things ready...',
    'Loading your progress...',
    'Almost there...',
  ];

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Particle animation controller
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _particleController,
        curve: Curves.linear,
      ),
    );

    _controller.forward();

    // Cycle through status messages
    _statusTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _statusMessages.length;
          _statusText = _statusMessages[_statusIndex];
        });
      }
    });

    // Navigate after 5 seconds (longer for testing)
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToHome();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _particleController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    final settings = ref.read(settingsProvider);
    
    if (settings.userName == null || settings.userName!.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
    } else if (settings.weightKg == null) {
      Navigator.pushReplacementNamed(context, '/profile-setup');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;
    final settings = ref.watch(settingsProvider);
    final userName = settings.userName ?? 'there';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    AppColors.darkBackgroundStart,
                    AppColors.darkBackgroundEnd,
                    AppColors.cardDark,
                  ]
                : [
                    AppColors.backgroundStart,
                    AppColors.backgroundEnd,
                    AppColors.waterLight.withOpacity(0.3),
                  ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background particles
              AnimatedBuilder(
                animation: _particleAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WaterParticlePainter(_particleAnimation.value),
                    size: MediaQuery.of(context).size,
                  );
                },
              ),
              // Main content
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    // Logo with animation
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.waterMedium.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/logo/aquatrack.png',
                              width: 140,
                              height: 140,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to icon if image fails to load
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.waterLight,
                                        AppColors.waterMedium,
                                        AppColors.waterDark,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.water_drop_rounded,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: AppDimens.paddingXXL),
                    
                    // Greeting text with slide animation
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: Transform.translate(
                        offset: Offset(0, _slideAnimation.value),
                        child: Column(
                          children: [
                            Text(
                              _getGreeting(),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w300,
                                color: theme.colorScheme.onSurface.withOpacity(0.8),
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: AppDimens.paddingS),
                            Text(
                              userName != 'there' 
                                  ? '$userName! 👋' 
                                  : 'Welcome! 👋',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: AppDimens.paddingXXL),
                    
                    // Status text with fade animation
                    Opacity(
                      opacity: _fadeAnimation.value * 0.8,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _statusText,
                          key: ValueKey(_statusText),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: AppDimens.paddingXXL),
                    
                    // Loading indicator
                    Opacity(
                      opacity: _fadeAnimation.value,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.waterMedium,
                          ),
                        ),
                      ),
                      ),
                    ],
                  );
                },
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }
}

/// Custom painter for animated water particles in background
class _WaterParticlePainter extends CustomPainter {
  final double animationValue;

  _WaterParticlePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.waterLight.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw floating water drops
    for (int i = 0; i < 8; i++) {
      final x = (size.width / 8) * i + (size.width / 16);
      final y = size.height * 0.2 + 
                (size.height * 0.6) * 
                ((animationValue + i * 0.1) % 1.0);
      
      final radius = 8.0 + (i % 3) * 4.0;
      
      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint..color = AppColors.waterLight.withOpacity(
          0.15 - (i % 3) * 0.05,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaterParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

