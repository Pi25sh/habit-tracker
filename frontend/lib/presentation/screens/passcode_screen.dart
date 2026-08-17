import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main_layout.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends State<PasscodeScreen> {
  static const String _singleUserId = 'shivani';
  static const String _singlePassword = 'shivba';

  final _emailController = TextEditingController(text: _singleUserId);
  final _passwordController = TextEditingController(text: _singlePassword);
  bool _rememberMe = true;
  bool _obscureText = true;

  void _onSignIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.toLowerCase() == _singleUserId && password == _singlePassword) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainLayout()),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invalid credentials'),
        backgroundColor: Colors.redAccent,
      )
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5), // Soft beige background
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            left: -50,
            child: _blob(const Color(0xFFF1F4EB), 200),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: _blob(const Color(0xFFE4ECD9), 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _blob(const Color(0xFFF5EFEB), 150),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: SizedBox(
                  width: 400,
                  child: Column(
                    children: [
                      // Language dropdown
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEFEFEF)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.language, size: 16, color: Color(0xFF2C4A3B)),
                              const SizedBox(width: 6),
                              Text('English', style: GoogleFonts.nunito(fontSize: 14, color: const Color(0xFF2C4A3B))),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF2C4A3B)),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Logo & Title
                      Icon(Icons.energy_savings_leaf_outlined, size: 48, color: const Color(0xFF2C4A3B)),
                      const SizedBox(height: 8),
                      Text(
                        'Habit Flow',
                        style: GoogleFonts.kalam(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2C4A3B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your day, your way.\nStay organized. Stay mindful. Stay you. ♡',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: const Color(0xFF5A5A5A),
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Form Card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back!',
                              style: GoogleFonts.nunito(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2C4A3B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Log in to continue your journey.',
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                color: const Color(0xFF7A7A7A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Email Field
                            Text(
                              'Email or Phone',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2C4A3B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _emailController,
                              hint: 'Enter your email or phone number',
                              icon: Icons.mail_outline,
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Password Field
                            Text(
                              'Password',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF2C4A3B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Enter your password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Remember me & Forgot Password
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                                      child: Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: _rememberMe ? const Color(0xFFE4ECD9) : Colors.transparent,
                                          border: Border.all(color: _rememberMe ? const Color(0xFF67793D) : const Color(0xFFD4D4D4)),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: _rememberMe 
                                          ? const Icon(Icons.check, size: 14, color: Color(0xFF2C4A3B))
                                          : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Remember me',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: const Color(0xFF2C4A3B),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    color: const Color(0xFF2C4A3B),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Log In Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _onSignIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3B6443), // Darker green
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Log In',
                                      style: GoogleFonts.nunito(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Or Divider
                            Row(
                              children: [
                                Expanded(child: Container(height: 1, color: const Color(0xFFEFEFEF))),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text('or', style: GoogleFonts.nunito(color: const Color(0xFF7A7A7A))),
                                ),
                                Expanded(child: Container(height: 1, color: const Color(0xFFEFEFEF))),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Social Icons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _socialIcon('assets/google.png', Icons.g_mobiledata),
                                const SizedBox(width: 24),
                                _socialIcon('assets/apple.png', Icons.apple),
                                const SizedBox(width: 24),
                                _socialIcon('assets/facebook.png', Icons.facebook),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Create account
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New here? ',
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    color: const Color(0xFF7A7A7A),
                                  ),
                                ),
                                Text(
                                  'Create an account ',
                                  style: GoogleFonts.nunito(
                                    fontSize: 15,
                                    color: const Color(0xFF2C4A3B),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF2C4A3B)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFEFEFEF)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F4EB), // Light green box
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF3B6443), size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword && _obscureText,
              style: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFF1E2420), fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.nunito(fontSize: 15, color: const Color(0xFFBDBDBD)),
                border: InputBorder.none,
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: const Color(0xFF7A7A7A),
                size: 20,
              ),
              onPressed: () => setState(() => _obscureText = !_obscureText),
            ),
          if (!isPassword) const SizedBox(width: 48), // Match padding for alignment
        ],
      ),
    );
  }

  Widget _socialIcon(String asset, IconData fallbackIcon) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(fallbackIcon, color: const Color(0xFF1E2420), size: 28),
    );
  }
}
