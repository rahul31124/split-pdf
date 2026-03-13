import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/lock_pdf_provider.dart';

class LockPdfScreen extends ConsumerStatefulWidget {
  const LockPdfScreen({super.key});

  @override
  ConsumerState<LockPdfScreen> createState() => _LockPdfScreenState();
}

class _LockPdfScreenState extends ConsumerState<LockPdfScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(lockPdfProvider);
      if (state.selectedFile == null) {
        await ref.read(lockPdfProvider.notifier).pickPdf();
        if (ref.read(lockPdfProvider).selectedFile == null && mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lockPdfProvider);
    final notifier = ref.read(lockPdfProvider.notifier);

    const Color primarySecurityColor = Color(0xFFD32F2F);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Protect PDF",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: state.isLoading
            ? _buildLoadingState(primarySecurityColor)
            : (state.selectedFile == null
            ? const SizedBox.shrink()
            : _buildWorkspace(context, state, notifier, primarySecurityColor)),
      ),
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      key: const ValueKey("loading_state"),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(color: primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            "Encrypting Document...\nApplying AES-256 Security.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey.shade600, fontWeight: FontWeight.w500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkspace(BuildContext context, LockPdfState state, LockPdfNotifier notifier, Color primaryColor) {
    return LayoutBuilder(
      key: const ValueKey("workspace_state"),
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)
                            ),
                            child: Icon(LucideIcons.fileLock2, size: 28, color: primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.selectedFile!.path.split('/').last,
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Ready to encrypt",
                                  style: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          if (state.lockedFile == null)
                            IconButton(
                              icon: const Icon(LucideIcons.edit3, color: Colors.grey, size: 20),
                              onPressed: () {
                                _passwordController.clear();
                                notifier.pickPdf();
                              },
                              tooltip: "Change File",
                            )
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: state.lockedFile != null
                          ? _buildSuccessView(state, primaryColor)
                          : _buildPasswordForm(notifier, primaryColor, context),
                    ),

                    const Spacer(),
                    const SizedBox(height: 20),
                    Center(
                      child: Opacity(
                        opacity: 0.85,
                        child: Image.asset(
                          'assets/splash.png',
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuccessView(LockPdfState state, Color primaryColor) {
    return Column(
      key: const ValueKey("success_view"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: Icon(LucideIcons.shieldCheck, color: Colors.green.shade600, size: 40),
              ),
              const SizedBox(height: 16),
              Text("PDF Secured!", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green.shade800)),
              const SizedBox(height: 8),
              Text(
                "Password is required to open this file.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Share.shareXFiles([XFile(state.lockedFile!.path)]),
          icon: const Icon(LucideIcons.share2, color: Colors.white),
          label: Text("Share Secure PDF", style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordForm(LockPdfNotifier notifier, Color primaryColor, BuildContext context) {
    return Column(
      key: const ValueKey("password_form"),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text("Set a Password", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2))],
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: !_isPasswordVisible,
            style: GoogleFonts.poppins(fontSize: 15),
            decoration: InputDecoration(
              hintText: "Enter strong password",
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
              prefixIcon: Icon(LucideIcons.keyRound, color: primaryColor),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            if (_passwordController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Please enter a password", style: GoogleFonts.poppins()),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }
            notifier.lockPdfWithPassword(_passwordController.text.trim());
          },
          icon: const Icon(LucideIcons.lock, color: Colors.white, size: 20),
          label: Text("Lock Document", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}