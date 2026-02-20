import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../services/hair_style_service.dart';
import '../theme/app_theme.dart';
import 'dart:convert';

class HairStylingScreen extends StatefulWidget {
  const HairStylingScreen({super.key});

  @override
  State<HairStylingScreen> createState() => _HairStylingScreenState();
}

class _HairStylingScreenState extends State<HairStylingScreen> {
  final HairStyleService _hairStyleService = HairStyleService();
  final ImagePicker _picker = ImagePicker();
  final String _sessionId = const Uuid().v4();

  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  bool _isLoading = false;
  String _currentStep = 'upload'; // upload, suggestions, generate, result

  // Hair style options
  List<String> _maleStyles = [];
  List<String> _femaleStyles = [];
  List<String> _colors = [];

  // User selections
  String _selectedGender = 'female';
  String? _selectedStyle;
  String? _selectedColor;
  Map<String, dynamic>? _suggestions;
  Map<String, dynamic>? _generatedResult;

  @override
  void initState() {
    super.initState();
    _loadHairStyleOptions();
  }

  Future<void> _loadHairStyleOptions() async {
    try {
      final options = await _hairStyleService.getHairStyleOptions();
      setState(() {
        _maleStyles = List<String>.from(options['male_styles'] ?? []);
        _femaleStyles = List<String>.from(options['female_styles'] ?? []);
        _colors = List<String>.from(options['colors'] ?? []);
      });
    } catch (e) {
      _showError('Failed to load style options: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _selectedImageName = image.name;
          _currentStep = 'suggestions';
          _suggestions = null;
          _generatedResult = null;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _getSuggestions() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _hairStyleService.getHairStyleSuggestions(
        imageBytes: _selectedImageBytes!,
        imageName: _selectedImageName,
        sessionId: _sessionId,
      );

      setState(() {
        _suggestions = suggestions;
        _isLoading = false;
        _currentStep = 'generate';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to get suggestions: $e');
    }
  }

  Future<void> _generateStyle() async {
    if (_selectedImageBytes == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _hairStyleService.generateHairStyle(
        imageBytes: _selectedImageBytes!,
        gender: _selectedGender,
        sessionId: _sessionId,
        imageName: _selectedImageName,
        style: _selectedStyle,
        color: _selectedColor,
      );

      setState(() {
        _generatedResult = result;
        _isLoading = false;
        _currentStep = 'result';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to generate style: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(isDark),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _buildContent(isDark),
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.charcoal, AppTheme.charcoalDeep]
              : [AppTheme.pearlBg, AppTheme.roseGoldLight],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.charcoal),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            'Hair Styling Studio',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.charcoal,
            ),
          ),
          const Spacer(),
          Icon(Icons.auto_awesome, color: AppTheme.gold, size: 28),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_currentStep == 'upload' && _selectedImageBytes == null) {
      return _buildUploadSection(isDark);
    } else if (_currentStep == 'suggestions' && _suggestions == null) {
      return _buildPreviewSection(isDark);
    } else if (_currentStep == 'generate' || (_currentStep == 'suggestions' && _suggestions != null)) {
      return _buildGenerateSection(isDark);
    } else if (_currentStep == 'result' && _generatedResult != null) {
      return _buildResultSection(isDark);
    }
    return _buildUploadSection(isDark);
  }

  Widget _buildUploadSection(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.charcoalMuted.withOpacity(0.5)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.gold.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.photo_camera, size: 80, color: AppTheme.gold.withOpacity(0.7)),
              const SizedBox(height: 24),
              Text(
                'Upload Your Photo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.charcoal,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Try different hairstyles and colors with AI',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(bool isDark) {
    return Column(
      children: [
        if (_selectedImageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              _selectedImageBytes!,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Get AI Recommendations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.charcoal,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Our AI will analyze your face shape and suggest the best styles for you',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Change Photo'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _getSuggestions,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Get Suggestions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGenerateSection(bool isDark) {
    final availableStyles = _selectedGender == 'male' ? _maleStyles : _femaleStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedImageBytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              _selectedImageBytes!,
              height: 250,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
        ],

        if (_suggestions != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: AppTheme.gold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'AI Suggestions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.charcoal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _suggestions.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Gender selection
        Text(
          'Gender',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOptionChip(
                'Female',
                _selectedGender == 'female',
                () => setState(() => _selectedGender = 'female'),
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOptionChip(
                'Male',
                _selectedGender == 'male',
                () => setState(() => _selectedGender = 'male'),
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Style selection
        Text(
          'Choose Style',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableStyles.map((style) {
            return _buildOptionChip(
              style,
              _selectedStyle == style,
              () => setState(() => _selectedStyle = style),
              isDark,
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Color selection
        Text(
          'Choose Color',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.charcoal,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((color) {
            return _buildOptionChip(
              color,
              _selectedColor == color,
              () => setState(() => _selectedColor = color),
              isDark,
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        // Generate button
        Center(
          child: ElevatedButton.icon(
            onPressed: (_selectedStyle != null && _selectedColor != null)
                ? _generateStyle
                : null,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Generate Style'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.gold,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection(bool isDark) {
    final success = _generatedResult?['success'] == true;
    final generatedImage = _generatedResult?['generated_image'];

    return Column(
      children: [
        if (success && generatedImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.memory(
              base64Decode(generatedImage),
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style Applied',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.charcoal,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Style: ${_generatedResult?['style_applied'] ?? 'N/A'}',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                ),
                Text(
                  'Color: ${_generatedResult?['color_applied'] ?? 'N/A'}',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                ),
                if (_generatedResult?['face_shape'] != null)
                  Text(
                    'Face Shape: ${_generatedResult?['face_shape']}',
                    style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 'generate';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                ),
                child: const Text('Try Another Style'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedImageBytes = null;
                    _currentStep = 'upload';
                    _suggestions = null;
                    _generatedResult = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Start Over'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                ),
              ),
            ],
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade700),
                const SizedBox(height: 16),
                Text(
                  'Failed to generate style',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _generatedResult?['error'] ?? 'Unknown error',
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.gold
              : (isDark ? AppTheme.charcoalMuted.withOpacity(0.5) : Colors.white.withOpacity(0.7)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.gold : AppTheme.gold.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white : AppTheme.charcoal),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.gold),
              const SizedBox(height: 16),
              const Text(
                'Processing...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
