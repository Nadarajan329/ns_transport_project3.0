import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ns_transport/core/constants/app_colors.dart';
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onChanged;
  final bool isGlassmorphic;

  const CustomTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.isGlassmorphic = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.primary;    
    final borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
    );

    final focusedBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: primaryColor, width: 2),
    );

    final errorBorderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    );

    Widget? buildSuffixIcon() {
      if (widget.isPassword) {
        return IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off : Icons.visibility,
            color: widget.isGlassmorphic ? Colors.white70 : Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        );
      }
      return widget.suffixIcon;
    }

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: GoogleFonts.inter(
        fontSize: 16,
        color: widget.isGlassmorphic ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        labelStyle: GoogleFonts.inter(color: widget.isGlassmorphic ? Colors.white70 : Colors.grey.shade700),
        hintStyle: GoogleFonts.inter(color: widget.isGlassmorphic ? Colors.white54 : Colors.grey.shade400),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: widget.isGlassmorphic ? Colors.white70 : Colors.grey.shade600)
            : null,
        suffixIcon: buildSuffixIcon(),
        filled: true,
        fillColor: widget.isGlassmorphic ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: widget.isGlassmorphic
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              )
            : borderStyle,
        enabledBorder: widget.isGlassmorphic
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
              )
            : borderStyle,
        focusedBorder: widget.isGlassmorphic
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              )
            : focusedBorderStyle,
        errorBorder: errorBorderStyle,
        focusedErrorBorder: errorBorderStyle,
      ),
    );
  }
}
