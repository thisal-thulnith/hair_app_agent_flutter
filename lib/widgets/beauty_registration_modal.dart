import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class BeautyRegistrationModal extends StatelessWidget {
  const BeautyRegistrationModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF9333EA),
            Color(0xFF3B82F6),
          ],
        ),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              FadeInDown(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Welcome message
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 100),
                child: const Column(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Welcome to Buff Salon!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please select your account type',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Customer option
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 200),
                child: _OptionCard(
                  icon: Icons.person,
                  title: 'Customer',
                  description: 'Get personalized beauty advice and recommendations',
                  onTap: () => Navigator.pop(context, 'customer'),
                ),
              ),

              const SizedBox(height: 16),

              // Salon Owner option
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 300),
                child: _OptionCard(
                  icon: Icons.store,
                  title: 'Salon Owner',
                  description: 'Manage your salon and connect with customers',
                  onTap: () => Navigator.pop(context, 'salon_owner'),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel button
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                delay: const Duration(milliseconds: 400),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
