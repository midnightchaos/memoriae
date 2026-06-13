import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/menta_service.dart';
import '../theme/app_theme.dart';

class MentaAssistant extends StatefulWidget {
  final bool floating;
  final Function(String)? onNavigate;
  
  const MentaAssistant({
    super.key, 
    this.floating = true,
    this.onNavigate,
  });

  @override
  State<MentaAssistant> createState() => _MentaAssistantState();
}

class _MentaAssistantState extends State<MentaAssistant> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Initialize Menta service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMenta();
    });
  }
  
  Future<void> _initializeMenta() async {
    final menta = context.read<MentaService>();
    if (!menta.isInitialized) {
      await menta.initialize();
      if (mounted) {
        await menta.speak('Hello! I\'m Menta, your personal assistant. How can I help you today?');
      }
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _toggleListening() async {
    final menta = context.read<MentaService>();
    
    if (menta.state == MentaState.listening) {
      await menta.stopListening();
      _animationController.reverse();
    } else {
      _animationController.repeat(reverse: true);
      final isListening = await menta.startListening();
      if (!isListening) {
        _animationController.reset();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not start voice recognition'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
  
  Widget _buildFloatingButton() {
    return Consumer<MentaService>(
      builder: (context, menta, _) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: FloatingActionButton(
                onPressed: _toggleListening,
                backgroundColor: AppColors.lavender400,
                child: _buildButtonIcon(menta.state),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildButtonIcon(MentaState state) {
    switch (state) {
      case MentaState.listening:
        return const Icon(Icons.mic, color: Colors.white);
      case MentaState.processing:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        );
      case MentaState.speaking:
        return const Icon(Icons.volume_up, color: Colors.white);
      case MentaState.error:
        return const Icon(Icons.error_outline, color: Colors.white);
      case MentaState.idle:
      default:
        return const Icon(Icons.mic_none, color: Colors.white);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.floating) {
      return Positioned(
        bottom: 24,
        right: 24,
        child: _buildFloatingButton(),
      );
    }
    
    return _buildFloatingButton();
  }
}
