// signup_screen_modern.dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:final_sai/screens/navigation_screen.dart'; // keep your existing screen
// Note: This is purely frontend. No backend calls. Verification flows are simulated.

class SignupScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Function(Locale) onLanguageChange;

  const SignupScreen({Key? key, required this.cameras, required this.onLanguageChange})
      : super(key: key);

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int TOTAL_STEPS = 5;

  // Animation controllers for subtle transitions
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Controllers for inputs (all optional / not required)
  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController fatherNameCtrl = TextEditingController();
  final TextEditingController motherNameCtrl = TextEditingController();
  final TextEditingController dobCtrl = TextEditingController();
  final TextEditingController heightCtrl = TextEditingController();
  final TextEditingController weightCtrl = TextEditingController();
  String socialCategory = 'General';

  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController altPhoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController addressLineCtrl = TextEditingController();
  final TextEditingController cityCtrl = TextEditingController();
  final TextEditingController stateCtrl = TextEditingController();
  final TextEditingController pincodeCtrl = TextEditingController();
  final TextEditingController schoolCollegeCtrl = TextEditingController();
  final TextEditingController emergencyContactNameCtrl = TextEditingController();
  final TextEditingController emergencyContactPhoneCtrl = TextEditingController();

  final TextEditingController aadharCtrl = TextEditingController();

  // Sports profile
  final List<String> sportsList = [
    'General',
    'Cricket',
    'Football',
    'Basketball',
    'Tennis',
    'Badminton',
    'Hockey',
    'Athletics',
    'Swimming',
    'Boxing',
    'Wrestling',
    'Weightlifting'
  ];
  String selectedSport = 'General';
  final TextEditingController experienceCtrl = TextEditingController();
  final TextEditingController languageCtrl = TextEditingController();
  final TextEditingController coachInfoCtrl = TextEditingController();
  final TextEditingController achievementsCtrl = TextEditingController();

  // Legal
  bool acceptedTerms = false;
  bool acceptedPrivacy = false;
  bool minorConsent = false; // special consent for minors

  // Verification simulated statuses
  bool phoneVerified = false;
  bool emailVerified = false;
  bool aadharVerified = false;
  bool photoVerified = false;

  // Loading / error states for simulated verification (frontend only)
  bool _isProcessing = false;
  String? _processingError;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();

    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    fatherNameCtrl.dispose();
    motherNameCtrl.dispose();
    dobCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    phoneCtrl.dispose();
    altPhoneCtrl.dispose();
    emailCtrl.dispose();
    addressLineCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    pincodeCtrl.dispose();
    schoolCollegeCtrl.dispose();
    emergencyContactNameCtrl.dispose();
    emergencyContactPhoneCtrl.dispose();
    aadharCtrl.dispose();
    experienceCtrl.dispose();
    languageCtrl.dispose();
    coachInfoCtrl.dispose();
    achievementsCtrl.dispose();

    super.dispose();
  }

  // ----- SIMULATED VERIFICATION HELPERS (FRONTEND ONLY) -----
  Future<void> _simulatePhoneOtpFlow() async {
    setState(() {
      _isProcessing = true;
      _processingError = null;
    });
    try {
      // simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      // show OTP dialog to accept a code (no real validation)
      final entered = await showDialog<String>(
        context: context,
        builder: (context) {
          final TextEditingController otpCtrl = TextEditingController();
          return AlertDialog(
            title: const Text('Enter OTP (simulated)'),
            content: TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Enter any 4-digit code'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, otpCtrl.text), child: const Text('Verify')),
            ],
          );
        },
      );

      if (entered != null) {
        // simulate verification success (but allow failure if user enters '0000')
        await Future.delayed(const Duration(milliseconds: 700));
        if (entered.trim() == '0000') {
          throw Exception('Simulated OTP failure');
        }
        setState(() {
          phoneVerified = true;
        });
        _showSnack('Phone verified (simulated)');
      }
    } catch (e) {
      setState(() {
        _processingError = e.toString();
      });
      _showSnack('Phone verification failed (simulated)');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _simulateEmailVerification() async {
    setState(() {
      _isProcessing = true;
      _processingError = null;
    });
    try {
      await Future.delayed(const Duration(seconds: 2));
      // show a dialog that "sent" verification link
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Email Verification (simulated)'),
          content: const Text('A verification link was "sent". Click confirm to mark as verified.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    emailVerified = true;
                  });
                  _showSnack('Email marked verified (simulated)');
                },
                child: const Text('Confirm')),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _processingError = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _simulateAadharVerification() async {
    setState(() {
      _isProcessing = true;
      _processingError = null;
    });
    try {
      await Future.delayed(const Duration(seconds: 2));
      // show modal with simple simulated result
      setState(() {
        aadharVerified = true;
      });
      _showSnack('Aadhar verification simulated success');
    } catch (e) {
      setState(() {
        _processingError = e.toString();
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _simulatePhotoVerification() async {
    setState(() {
      _isProcessing = true;
      _processingError = null;
    });
    try {
      // simulate "camera" take or upload
      await Future.delayed(const Duration(seconds: 2));
      // simulate AI processing with chance of "failure"
      final success = DateTime.now().millisecond % 7 != 0; // arbitrary small chance to fail
      if (!success) throw Exception('Simulated AI failed to verify face');
      setState(() {
        photoVerified = true;
      });
      _showSnack('Photo verification simulated success');
    } catch (e) {
      setState(() {
        _processingError = e.toString();
      });
      _showSnack('Photo verification simulated failed');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ----- UI BUILD -----
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // SAI-ish palette (deep blue + accent saffron)
    const saiBlue = Color(0xFF0D47A1);
    const saiAccent = Color(0xFFFF8F00);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF),
      // --- AppBar with icon + text as requested ---
      appBar: AppBar(
        backgroundColor: saiBlue, // solid blue (no gradient)
        elevation: 2,
        title: Row(
          children: const [
            Icon(Icons.sports, size: 26, color: Colors.white),
            SizedBox(width: 10),
            Text('SAI Portal', style: TextStyle(fontWeight: FontWeight.bold,
            color: Colors.white)),
          ],
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final contentPadding = EdgeInsets.symmetric(horizontal: isWide ? 48 : 18, vertical: 18);

          return Padding(
            padding: contentPadding,
            child: Column(
              children: [
                // Header text under the AppBar (create your own ...)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 6),
                      Text('Create Your Professional Athlete Profile',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('A simple 5-step registration to join the SAI talent network',
                          style: TextStyle(fontSize: 13, color: Colors.black54)),
                      SizedBox(height: 12),
                    ],
                  ),
                ),

                _buildStepIcons(saiBlue, saiAccent),
                const SizedBox(height: 16),
                Expanded(
                  child: Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: _buildPageView(isWide, saiBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildBottomNavigation(saiBlue),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepIcons(Color saiBlue, Color saiAccent) {
    final steps = [
      {'label': 'Personal', 'icon': Icons.person},
      {'label': 'Contact', 'icon': Icons.contact_phone},
      {'label': 'Verify', 'icon': Icons.verified_user},
      {'label': 'Sports', 'icon': Icons.sports_soccer},
      {'label': 'Legal', 'icon': Icons.rule},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(steps.length, (i) {
          final active = i == _currentStep;
          return GestureDetector(
            onTap: () {
              _goToStep(i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active ? saiBlue.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: active ? saiBlue : Colors.transparent),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: active ? saiBlue : Colors.grey.shade200,
                    child: Icon(steps[i]['icon'] as IconData, color: active ? Colors.white : Colors.black54, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(steps[i]['label'] as String, style: TextStyle(fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPageView(bool isWide, Color saiBlue) {
    return SizedBox(
      width: double.infinity,
      child: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentStep = index;
            _fadeController.forward(from: 0.0);
          });
        },
        children: [
          _wrapCard(_personalInfoPage(isWide)),
          _wrapCard(_contactAddressPage()),
          _wrapCard(_verificationPage()),
          _wrapCard(_sportsProfilePage()),
          _wrapCard(_legalConsentPage()),
        ],
      ),
    );
  }

  Widget _wrapCard(Widget child) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(child: child),
      ),
    );
  }

  // ------------------- Pages -------------------

  Widget _personalInfoPage(bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Personal Information', 'Names, DOB, physical stats, category'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildTextField('First name', controller: firstNameCtrl, widthFactor: isWide ? 0.45 : 1),
            _buildTextField('Last name', controller: lastNameCtrl, widthFactor: isWide ? 0.45 : 1),
            _buildTextField('Father\'s name', controller: fatherNameCtrl, widthFactor: isWide ? 0.45 : 1),
            _buildTextField('Mother\'s name', controller: motherNameCtrl, widthFactor: isWide ? 0.45 : 1),
            _buildTextField('Date of Birth', controller: dobCtrl, prefixIcon: Icons.calendar_today, widthFactor: isWide ? 0.45 : 1, readOnly: true, onTap: _pickDob),
            _buildTextField('Height (cm)', controller: heightCtrl, widthFactor: isWide ? 0.45 : 1, keyboardType: TextInputType.number),
            _buildTextField('Weight (kg)', controller: weightCtrl, widthFactor: isWide ? 0.45 : 1, keyboardType: TextInputType.number),
            _buildDropdown('Social Category', ['General', 'SC', 'ST', 'OBC', 'EWS'], (val) {
              setState(() {
                socialCategory = val ?? 'General';
              });
            }, widthFactor: isWide ? 0.45 : 1),
          ],
        ),
        const SizedBox(height: 18),
        _smallInfoCard('Note', 'Fields are optional here. Provide information to help with official records and assessments.'),
      ],
    );
  }

  Widget _contactAddressPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Contact & Address', 'Complete contact details and emergency info'),
        const SizedBox(height: 12),
        _buildTextField('Primary Phone', controller: phoneCtrl, prefixIcon: Icons.phone, keyboardType: TextInputType.phone),
        _buildTextField('Alternate Phone', controller: altPhoneCtrl, prefixIcon: Icons.phone_android, keyboardType: TextInputType.phone),
        Row(children: [
          Expanded(child: _buildTextField('Email', controller: emailCtrl, prefixIcon: Icons.email, keyboardType: TextInputType.emailAddress)),
          const SizedBox(width: 12),
          _verificationSmallButton('Verify Email', emailVerified ? Icons.check_circle : Icons.send, onTap: _simulateEmailVerification, done: emailVerified),
        ]),
        const SizedBox(height: 8),
        _buildTextField('Address line', controller: addressLineCtrl, maxLines: 2),
        Wrap(spacing: 12, children: [
          _buildTextField('City', controller: cityCtrl, widthFactor: 0.3),
          _buildTextField('State', controller: stateCtrl, widthFactor: 0.3),
          _buildTextField('Pincode', controller: pincodeCtrl, widthFactor: 0.3, keyboardType: TextInputType.number),
        ]),
        const SizedBox(height: 8),
        _buildTextField('School / College', controller: schoolCollegeCtrl),
        const SizedBox(height: 10),
        _sectionHeader('Emergency Contact', 'Person to reach in case of urgency'),
        const SizedBox(height: 8),
        _buildTextField('Emergency name', controller: emergencyContactNameCtrl),
        _buildTextField('Emergency phone', controller: emergencyContactPhoneCtrl),
      ],
    );
  }

  Widget _verificationPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Verification', 'Phone OTP, Email, Photo & Aadhar (simulated)'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('Aadhar number', controller: aadharCtrl, prefixIcon: Icons.credit_card, keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            _verificationSmallButton('Verify Aadhar', aadharVerified ? Icons.check_circle : Icons.verified, onTap: _simulateAadharVerification, done: aadharVerified),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildTextField('Phone (for OTP)', controller: phoneCtrl, prefixIcon: Icons.phone)),
          const SizedBox(width: 12),
          _verificationSmallButton('Send OTP', phoneVerified ? Icons.check_circle : Icons.message, onTap: _simulatePhoneOtpFlow, done: phoneVerified),
        ]),
        const SizedBox(height: 12),
        _buildCardTile(
          title: 'Photo Verification',
          subtitle: photoVerified ? 'Selfie verified (simulated)' : 'Upload or capture a selfie for identity checks',
          actionLabel: photoVerified ? 'Verified' : 'Take / Upload Selfie',
          onTapAction: _simulatePhotoVerification,
          done: photoVerified,
        ),
        if (_isProcessing) ...[
          const SizedBox(height: 12),
          Center(child: Column(children: const [CircularProgressIndicator(), SizedBox(height: 8), Text('Processing...')])),
        ],
        if (_processingError != null) ...[
          const SizedBox(height: 12),
          Text('Last error: $_processingError', style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 12),
        _smallInfoCard('Privacy', 'Your verification data stays local to this device unless you integrate a backend. This demo simulates verification UI only.'),
      ],
    );
  }

  Widget _sportsProfilePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Sports Profile', 'Sport, experience, coaching & achievements'),
        const SizedBox(height: 12),
        _buildDropdown('Primary sport', sportsList, (val) {
          setState(() {
            selectedSport = val ?? selectedSport;
          });
        }),
        const SizedBox(height: 8),
        _buildTextField('Experience (years)', controller: experienceCtrl, keyboardType: TextInputType.number),
        _buildTextField('Language preference', controller: languageCtrl),
        _buildTextField('Coach / Academy', controller: coachInfoCtrl),
        _buildTextField('Previous achievements', controller: achievementsCtrl, maxLines: 3),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blueGrey.shade100)),
          child: Row(
            children: const [
              Icon(Icons.emoji_events, size: 36, color: Colors.deepOrange),
              SizedBox(width: 12),
              Expanded(child: Text('Add photos or PDF of certificates later in your profile. This screen only captures text summary.')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legalConsentPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Terms & Consent', 'Legal compliance and permission management'),
        const SizedBox(height: 12),
        CheckboxListTile(
          value: acceptedTerms,
          onChanged: (v) => setState(() => acceptedTerms = v ?? false),
          title: const Text('I accept the Terms & Conditions (frontend only)'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: acceptedPrivacy,
          onChanged: (v) => setState(() => acceptedPrivacy = v ?? false),
          title: const Text('I consent to the Privacy Policy (frontend only)'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          value: minorConsent,
          onChanged: (v) => setState(() => minorConsent = v ?? false),
          title: const Text('Special consent for minors (under 18)'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 12),
        _smallInfoCard('Summary', 'This is a frontend-only registration flow. No data is sent to any server here.'),
        const SizedBox(height: 12),
        _buildSummaryTile(),
      ],
    );
  }

  // ------------------- Shared small UI parts -------------------

  Widget _sectionHeader(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 4),
      Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54)),
    ]);
  }

  Widget _buildTextField(String label,
      {TextEditingController? controller,
      IconData? prefixIcon,
      int maxLines = 1,
      double? widthFactor,
      bool readOnly = false,
      void Function()? onTap,
      TextInputType? keyboardType}) {
    final field = Container(
      width: widthFactor != null ? MediaQuery.of(context).size.width * widthFactor : double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        ),
      ),
    );
    return field;
  }

  Widget _buildDropdown(String label, List<String> items, ValueChanged<String?> onChanged, {double? widthFactor}) {
    return Container(
      width: widthFactor != null ? MediaQuery.of(context).size.width * widthFactor : double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        value: items.contains(selectedSport) && label == 'Primary sport' ? selectedSport : items.first,
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _verificationSmallButton(String label, IconData icon, {required VoidCallback onTap, bool done = false}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(done ? 'Done' : label),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: done ? Colors.green : null,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  Widget _buildCardTile({
    required String title,
    required String subtitle,
    required String actionLabel,
    required VoidCallback onTapAction,
    bool done = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 6))
      ]),
      child: Row(
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Colors.black54)),
            ]),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTapAction,
            child: Text(done ? 'Verified' : actionLabel),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              backgroundColor: done ? Colors.green : null,
              foregroundColor: Colors.white,
            ),
          )
        ],
      ),
    );
  }

  Widget _smallInfoCard(String title, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Row(children: [
        CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.info, color: Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(body, style: const TextStyle(color: Colors.black54))])),
      ]),
    );
  }

  Widget _buildSummaryTile() {
    final summary = <String>[];
    if (firstNameCtrl.text.isNotEmpty || lastNameCtrl.text.isNotEmpty) summary.add('Name: ${firstNameCtrl.text} ${lastNameCtrl.text}');
    if (selectedSport.isNotEmpty) summary.add('Sport: $selectedSport');
    if (phoneCtrl.text.isNotEmpty) summary.add('Phone: ${phoneCtrl.text}');
    if (emailCtrl.text.isNotEmpty) summary.add('Email: ${emailCtrl.text}');
    summary.add('Phone verified: ${phoneVerified ? 'Yes' : 'No'}');
    summary.add('Email verified: ${emailVerified ? 'Yes' : 'No'}');
    summary.add('Photo verified: ${photoVerified ? 'Yes' : 'No'}');
    summary.add('Aadhar verified: ${aadharVerified ? 'Yes' : 'No'}');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quick Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...summary.map((s) => Text('• $s', style: const TextStyle(color: Colors.black87))),
      ]),
    );
  }

  Widget _buildBottomNavigation(Color saiBlue) {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: _previousStep,
              child: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Back')),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _currentStep == TOTAL_STEPS - 1 ? _completeAndProceed : _nextStep,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(_currentStep == TOTAL_STEPS - 1 ? 'Complete Setup' : 'Next'),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: saiBlue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ],
    );
  }

  // ------------------- Navigation logic (no blocking) -------------------

  void _goToStep(int index) {
    setState(() {
      _currentStep = index;
      _pageController.jumpToPage(index);
      _fadeController.forward(from: 0.0);
    });
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _nextStep() {
    if (_currentStep < TOTAL_STEPS - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  Future<void> _completeAndProceed() async {
    // FRONTEND ONLY: show a final summary and allow user to continue (no required fields)
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Finalize profile'),
        content: SingleChildScrollView(child: _buildSummaryTile()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Edit')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => MainNavigationScreen(
                    cameras: widget.cameras,
                    onLanguageChange: widget.onLanguageChange,
                  ),
                ),
              );
            },
            child: const Text('Finish & Go to App'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D47A1), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  // ------------------- Helpers -------------------
  Future<void> _pickDob() async {
    final date = await showDatePicker(context: context, initialDate: DateTime(2005), firstDate: DateTime(1950), lastDate: DateTime.now());
    if (date != null) {
      setState(() {
        dobCtrl.text = '${date.day}/${date.month}/${date.year}';
      });
    }
  }
}
