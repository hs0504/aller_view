// import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import '../../services/auth_service.dart';
// import '../../services/profile_service.dart';
// import '../onboarding/main_home_screen.dart';
//
// class AuthScreen extends StatefulWidget {
//   final String nickname;
//   final List<String> allergies;
//   final List<String> preferredIngredients;
//
//   const AuthScreen({
//     super.key,
//     required this.nickname,
//     required this.allergies,
//     required this.preferredIngredients,
//   });
//
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }
//
// class _AuthScreenState extends State<AuthScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//
//   bool _isSignup = true;
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//
//   final _authService = AuthService();
//   final _profileService = ProfileService();
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _onEmailSubmit() async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//
//     AuthResult result;
//     if (_isSignup) {
//       // 먼저 프로필 로컬 저장
//       await _profileService.saveProfile(
//         nickname: widget.nickname,
//         allergies: widget.allergies,
//         preferredIngredients: widget.preferredIngredients,
//       );
//       result = await _authService.signup(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//         nickname: widget.nickname,
//         allergies: widget.allergies,
//         preferredIngredients: widget.preferredIngredients,
//       );
//     } else {
//       result = await _authService.login(
//         email: _emailController.text.trim(),
//         password: _passwordController.text,
//       );
//     }
//
//     if (!mounted) return;
//     setState(() => _isLoading = false);
//
//     if (result.isSuccess) {
//       _navigateToHome();
//     } else {
//       _showError(result.errorMessage);
//     }
//   }
//
//   Future<void> _onGoogleSignIn() async {
//     setState(() => _isLoading = true);
//     try {
//       await Supabase.instance.client.auth.signInWithOAuth(
//         OAuthProvider.google,
//       );
//       // OAuth 완료 후 딥링크로 돌아오면 세션이 자동 설정됨
//       final session = Supabase.instance.client.auth.currentSession;
//       if (session == null) {
//         setState(() => _isLoading = false);
//         return;
//       }
//
//       await _profileService.saveProfile(
//         nickname: widget.nickname,
//         allergies: widget.allergies,
//         preferredIngredients: widget.preferredIngredients,
//       );
//
//       final result = await _authService.socialComplete(
//         supabaseToken: session.accessToken,
//         nickname: widget.nickname,
//         allergies: widget.allergies,
//         preferredIngredients: widget.preferredIngredients,
//       );
//
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//
//       if (result.isSuccess) {
//         _navigateToHome();
//       } else {
//         _showError(result.errorMessage);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isLoading = false);
//       _showError('Google 로그인에 실패했습니다');
//     }
//   }
//
//   Future<void> _onGuest() async {
//     await _profileService.saveProfile(
//       nickname: widget.nickname,
//       allergies: widget.allergies,
//       preferredIngredients: widget.preferredIngredients,
//     );
//     await _profileService.setGuest(true);
//     if (!mounted) return;
//     _navigateToHome();
//   }
//
//   void _navigateToHome() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       PageRouteBuilder(
//         transitionDuration: const Duration(milliseconds: 400),
//         pageBuilder: (_, __, ___) => const MainHomeScreen(),
//         transitionsBuilder: (_, animation, __, child) {
//           return FadeTransition(
//             opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
//             child: child,
//           );
//         },
//       ),
//       (route) => false,
//     );
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFFFF5F7),
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFFFF5F7),
//         elevation: 0,
//         surfaceTintColor: Colors.transparent,
//         centerTitle: true,
//         title: const Text(
//           "계정 연결",
//           style: TextStyle(
//             fontSize: 20,
//             fontWeight: FontWeight.w700,
//             color: Color(0xFF2D2D2D),
//           ),
//         ),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             // 탭 바
//             Container(
//               margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: TabBar(
//                 controller: _tabController,
//                 indicator: BoxDecoration(
//                   color: const Color(0xFFF06292),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 indicatorSize: TabBarIndicatorSize.tab,
//                 labelColor: Colors.white,
//                 unselectedLabelColor: Colors.grey,
//                 labelStyle: const TextStyle(fontWeight: FontWeight.w600),
//                 tabs: const [
//                   Tab(text: "이메일"),
//                   Tab(text: "Google"),
//                 ],
//               ),
//             ),
//
//             Expanded(
//               child: TabBarView(
//                 controller: _tabController,
//                 children: [
//                   _buildEmailTab(),
//                   _buildGoogleTab(),
//                 ],
//               ),
//             ),
//
//             // 게스트 버튼
//             Padding(
//               padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
//               child: TextButton(
//                 onPressed: _isLoading ? null : _onGuest,
//                 child: const Text(
//                   "게스트로 이용하기",
//                   style: TextStyle(color: Colors.black45, fontSize: 14),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmailTab() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       child: Form(
//         key: _formKey,
//         child: Column(
//           children: [
//             // 회원가입 / 로그인 토글
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 _buildToggleButton("회원가입", _isSignup, () {
//                   setState(() => _isSignup = true);
//                 }),
//                 const SizedBox(width: 8),
//                 _buildToggleButton("로그인", !_isSignup, () {
//                   setState(() => _isSignup = false);
//                 }),
//               ],
//             ),
//             const SizedBox(height: 24),
//
//             // 이메일
//             TextFormField(
//               controller: _emailController,
//               keyboardType: TextInputType.emailAddress,
//               decoration: _inputDeco("이메일", Icons.email_outlined),
//               validator: (v) {
//                 if (v == null || v.trim().isEmpty) return '이메일을 입력해주세요';
//                 if (!v.contains('@')) return '이메일 형식을 확인해주세요';
//                 return null;
//               },
//             ),
//             const SizedBox(height: 12),
//
//             // 비밀번호
//             TextFormField(
//               controller: _passwordController,
//               obscureText: _obscurePassword,
//               decoration: _inputDeco("비밀번호", Icons.lock_outline).copyWith(
//                 suffixIcon: IconButton(
//                   icon: Icon(
//                     _obscurePassword
//                         ? Icons.visibility_off_outlined
//                         : Icons.visibility_outlined,
//                     color: Colors.grey,
//                   ),
//                   onPressed: () =>
//                       setState(() => _obscurePassword = !_obscurePassword),
//                 ),
//               ),
//               validator: (v) {
//                 if (v == null || v.isEmpty) return '비밀번호를 입력해주세요';
//                 if (_isSignup && v.length < 8) return '비밀번호는 8자 이상이어야 합니다';
//                 return null;
//               },
//             ),
//             const SizedBox(height: 24),
//
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: ElevatedButton(
//                 onPressed: _isLoading ? null : _onEmailSubmit,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFF06292),
//                   foregroundColor: Colors.white,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//                 child: _isLoading
//                     ? const SizedBox(
//                         width: 20,
//                         height: 20,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : Text(
//                         _isSignup ? "회원가입" : "로그인",
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildGoogleTab() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               "Google 계정으로\n간편하게 시작하세요",
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xFF2D2D2D),
//                 height: 1.5,
//               ),
//             ),
//             const SizedBox(height: 32),
//             SizedBox(
//               width: double.infinity,
//               height: 50,
//               child: OutlinedButton.icon(
//                 onPressed: _isLoading ? null : _onGoogleSignIn,
//                 icon: const Text("G", style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF4285F4),
//                 )),
//                 label: const Text(
//                   "Google로 계속하기",
//                   style: TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF2D2D2D),
//                   ),
//                 ),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: Color(0xFFE0E0E0)),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildToggleButton(String label, bool selected, VoidCallback onTap) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
//         decoration: BoxDecoration(
//           color: selected ? const Color(0xFFF06292) : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: selected ? const Color(0xFFF06292) : const Color(0xFFE0E0E0),
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontWeight: FontWeight.w600,
//             color: selected ? Colors.white : Colors.black54,
//           ),
//         ),
//       ),
//     );
//   }
//
//   InputDecoration _inputDeco(String hint, IconData icon) {
//     return InputDecoration(
//       hintText: hint,
//       hintStyle: TextStyle(color: Colors.grey[400]),
//       prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
//       filled: true,
//       fillColor: Colors.white,
//       contentPadding:
//           const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: BorderSide.none,
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Color(0xFFF06292), width: 2),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Colors.redAccent),
//       ),
//       focusedErrorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(14),
//         borderSide: const BorderSide(color: Colors.redAccent, width: 2),
//       ),
//     );
//   }
// }