import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AnimatedLogo extends StatefulWidget {
  final double size;
  final Color color;
  final Duration animationDuration;
  final bool enablePulse;
  final bool enableRotation;

  const AnimatedLogo({
    super.key,
    this.size = 60,
    this.color = Colors.white,
    this.animationDuration = const Duration(seconds: 2),
    this.enablePulse = true,
    this.enableRotation = false,
  });

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Pulse animation
    _pulseController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.enablePulse) {
      _pulseController.repeat(reverse: true);
    }

    if (widget.enableRotation) {
      _rotationController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _rotationController]),
      builder: (context, child) {
        Widget logo = Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.8),
                widget.color.withValues(alpha: 0.6),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            PhosphorIcons.buildings(),
            color: Colors.white,
            size: widget.size * 0.6,
          ),
        );

        if (widget.enablePulse) {
          logo = Transform.scale(
            scale: _pulseAnimation.value,
            child: logo,
          );
        }

        if (widget.enableRotation) {
          logo = Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: logo,
          );
        }

        return logo;
      },
    );
  }
}

class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color particleColor;
  final double maxSize;
  final double minSize;

  const FloatingParticles({
    super.key,
    this.particleCount = 20,
    this.particleColor = Colors.white,
    this.maxSize = 4,
    this.minSize = 1,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    particles = List.generate(widget.particleCount, (index) {
      return Particle(
        x: (index * 50.0) % 300,
        y: (index * 30.0) % 200,
        size: widget.minSize +
            (widget.maxSize - widget.minSize) * (index % 3) / 2,
        speed: 0.5 + (index % 3) * 0.3,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(
            particles: particles,
            animationValue: _controller.value,
            color: widget.particleColor,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speed;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = (particle.x + animationValue * particle.speed * 100) % size.width;
      final y = (particle.y + animationValue * particle.speed * 50) % size.height;
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}