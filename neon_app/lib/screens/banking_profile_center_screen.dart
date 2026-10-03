import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'add_beneficiary_screen.dart';
import 'create_mpin_screen.dart';

class BankingProfileCenterScreen extends StatefulWidget {
  final UserModel user;
  final Function() onProfileUpdated;
  final Function()? onOpenMpinModal;

  const BankingProfileCenterScreen({
    super.key,
    required this.user,
    required this.onProfileUpdated,
    this.onOpenMpinModal,
  });

  @override
  State<BankingProfileCenterScreen> createState() => _BankingProfileCenterScreenState();
}

class _BankingProfileCenterScreenState extends State<BankingProfileCenterScreen> {
  late UserModel _currentUser;
  bool _isMasked = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _refreshProfile();
  }

  Future<void> _refreshProfile() async {
    final updated = await ApiService.getUserDetails(_currentUser.appId, sessionId: _currentUser.sessionId);
    if (updated != null && mounted) {
      setState(() => _currentUser = updated);
      widget.onProfileUpdated();
    }
  }

  // Section 1: Personal Info Modal
  void _openPersonalInfoModal() {
    final nameCtrl = TextEditingController(text: _currentUser.fullName);
    final emailCtrl = TextEditingController(text: _currentUser.email);
    final phoneCtrl = TextEditingController(text: _currentUser.phone);
    final addressCtrl = TextEditingController(text: _currentUser.address);
    final dobCtrl = TextEditingController(text: _currentUser.dob);
    final genderCtrl = TextEditingController(text: _currentUser.gender);
    final nationalIdCtrl = TextEditingController(text: _currentUser.nationalId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: "Full Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(labelText: "Email Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(labelText: "Mobile Phone Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(labelText: "Residential Address", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dobCtrl,
                      decoration: InputDecoration(labelText: "Date of Birth", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: genderCtrl,
                      decoration: InputDecoration(labelText: "Gender", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nationalIdCtrl,
                decoration: InputDecoration(labelText: "National ID / Aadhaar", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPink,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final res = await ApiService.updateProfile(
                      _currentUser.appId,
                      {
                        "full_name": nameCtrl.text.trim(),
                        "email": emailCtrl.text.trim(),
                        "phone": phoneCtrl.text.trim(),
                        "address": addressCtrl.text.trim(),
                        "dob": dobCtrl.text.trim(),
                        "gender": genderCtrl.text.trim(),
                        "national_id": nationalIdCtrl.text.trim(),
                      },
                    );
                    if (res['success'] == true) {
                      await _refreshProfile();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Personal info saved to backend!")));
                      }
                    }
                  },
                  child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section 2: Banking Info Modal
  void _openBankingInfoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Swiss & International Banking Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => setModalState(() => _isMasked = !_isMasked),
                    icon: Icon(_isMasked ? Icons.visibility_off : Icons.visibility, size: 16),
                    label: Text(_isMasked ? "Show" : "Hide"),
                  )
                ],
              ),
              const SizedBox(height: 12),
              _buildDetailTile("Main Account Number", _isMasked ? "•••• •••• ${(_currentUser.accountNumber.length > 4 ? _currentUser.accountNumber.substring(_currentUser.accountNumber.length - 4) : '4821')}" : _currentUser.accountNumber),
              _buildDetailTile("Swiss IBAN", _isMasked ? "CH93 •••• •••• •••• 4821" : "CH93 0023 0000 3835 1908 737"),
              _buildDetailTile("SWIFT / BIC", _isMasked ? "NEONCH••••" : "NEONCHZZ800"),
              _buildDetailTile("Routing / Clearing", _isMasked ? "••••••" : "000238"),
              _buildDetailTile("Primary Currency", "CHF (Swiss Franc)"),
              _buildDetailTile("Account Tier", _currentUser.accountType),
            ],
          ),
        ),
      ),
    );
  }

  // Section 3: Country Specific Banking
  void _openCountryBankingModal() {
    String selectedCountry = 'Switzerland';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Country-Specific Banking Identifiers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCountry,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                items: ['Switzerland', 'India', 'Singapore', 'UAE', 'USA', 'UK', 'Canada', 'Australia']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setModalState(() => selectedCountry = val!),
              ),
              const SizedBox(height: 16),
              if (selectedCountry == 'Switzerland') ...[
                _buildDetailTile("IBAN", "CH93 0023 0000 3835 1908 737"),
                _buildDetailTile("SIC Clearing No.", "00230"),
                _buildDetailTile("SWIFT/BIC", "NEONCHZZ800"),
              ] else if (selectedCountry == 'India') ...[
                _buildDetailTile("IFSC Code", "NEON0001829"),
                _buildDetailTile("UPI Handle", "${_currentUser.phone}@neon"),
                _buildDetailTile("NEFT/RTGS Clearing", "Enabled"),
              ] else if (selectedCountry == 'USA') ...[
                _buildDetailTile("ACH Routing Number", "021000021"),
                _buildDetailTile("FedWire Routing", "021000021"),
                _buildDetailTile("Account Number", "10492810398"),
              ] else if (selectedCountry == 'UK') ...[
                _buildDetailTile("Sort Code", "20-04-15"),
                _buildDetailTile("UK Account Number", "83910248"),
                _buildDetailTile("Faster Payments", "Active"),
              ] else ...[
                _buildDetailTile("Global SWIFT BIC", "NEONCHZZ800"),
                _buildDetailTile("Correspondent Bank", "UBS AG Zurich"),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Section 4: Nominee Modal
  void _openNomineeModal() {
    final nomineeNameCtrl = TextEditingController(text: "Sophia S.");
    final relationCtrl = TextEditingController(text: "Spouse");
    final contactCtrl = TextEditingController(text: "+41 79 123 4567");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Account Nominee Management", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(controller: nomineeNameCtrl, decoration: InputDecoration(labelText: "Nominee Full Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 10),
            TextField(controller: relationCtrl, decoration: InputDecoration(labelText: "Relationship", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 10),
            TextField(controller: contactCtrl, decoration: InputDecoration(labelText: "Contact Phone Number", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominee details updated successfully!")));
                },
                child: const Text("Save Nominee Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateMpinModalInternal() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMpinScreen(user: _currentUser),
      ),
    );
    if (res == true) {
      await _refreshProfile();
    }
  }

  // Section 5: Generic Display Sheet for Tax, Security, Legal, Support, Settings, Documents
  void _openSimpleInfoSheet(String title, List<Map<String, String>> items) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) => _buildDetailTile(item['key']!, item['val']!)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.neonPink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.neonPink, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("International Banking Center", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Banking Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.neonPink,
                    child: Text(
                      _currentUser.fullName.isNotEmpty ? _currentUser.fullName[0].toUpperCase() : 'N',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser.fullName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Client ID: ${_currentUser.appId}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                              child: Text(_currentUser.status.toUpperCase(), style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            const Text("🇨🇭 Switzerland", style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text("Account & Banking Services", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            _buildMenuTile(Icons.person_outline_rounded, "Personal Information", "Name, DOB, Contact & Residential Address", _openPersonalInfoModal),
            _buildMenuTile(Icons.account_balance_rounded, "Banking Information", "Masked Account, SWIFT, IBAN & Routing", _openBankingInfoModal),
            _buildMenuTile(Icons.public_rounded, "International Banking", "Country-specific clearing & identifier lookup", _openCountryBankingModal),
            _buildMenuTile(Icons.people_outline_rounded, "Beneficiaries & Payees", "Manage trusted transfer accounts", () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AddBeneficiaryScreen(user: _currentUser)));
            }),
            _buildMenuTile(Icons.assignment_ind_outlined, "Nominee Details", "View and update account beneficiary nominee", _openNomineeModal),
            _buildMenuTile(Icons.verified_user_outlined, "KYC & Identity Verification", "Status: VERIFIED (FINMA Compliant)", () {
              _openSimpleInfoSheet("KYC & Verification Status", [
                {"key": "Verification Status", "val": "VERIFIED"},
                {"key": "Identity Doc", "val": "Passport / National ID Verified"},
                {"key": "Address Doc", "val": "Utility Bill Approved"},
                {"key": "Verification Date", "val": "12 Jan 2026"},
              ]);
            }),
            _buildMenuTile(Icons.gavel_rounded, "Tax & International Residency", "FATCA, CRS & Tax Residency status", () {
              _openSimpleInfoSheet("Tax & Residency Declaration", [
                {"key": "Tax Residence", "val": "Switzerland (CH)"},
                {"key": "TIN / Tax ID", "val": "CHE-109.824.112"},
                {"key": "FATCA Status", "val": "Non-US Person"},
                {"key": "CRS Reporting", "val": "Active Standard"},
              ]);
            }),
            _buildMenuTile(
              Icons.shield_outlined,
              "Transaction MPIN",
              _currentUser.hasMpin ? "Status: Enabled ✓ (Click to Change)" : "Status: Not Set (Click to Create)",
              () {
                if (widget.onOpenMpinModal != null) {
                  widget.onOpenMpinModal!();
                } else {
                  _openCreateMpinModalInternal();
                }
              },
            ),
            _buildMenuTile(Icons.security_rounded, "Security & Auth Center", "Passwords, Biometrics, Login History", () {
              _openSimpleInfoSheet("Security Center", [
                {"key": "Passcode/PIN", "val": "Configured"},
                {"key": "Biometric Auth", "val": "Face ID Enabled"},
                {"key": "2FA Status", "val": "Active (SMS/Email)"},
                {"key": "Active Sessions", "val": "This Device Only"},
              ]);
            }),
            _buildMenuTile(Icons.notifications_none_rounded, "Notification Preferences", "Manage SMS, Push and Email alerts", () {
              _openSimpleInfoSheet("Notification Preferences", [
                {"key": "Transaction Alerts", "val": "Enabled (Instant)"},
                {"key": "Security Alerts", "val": "Enabled"},
                {"key": "Email Statements", "val": "Monthly"},
              ]);
            }),
            _buildMenuTile(Icons.description_outlined, "Documents & Statements", "Download official bank statements & disclosures", () {
              _openSimpleInfoSheet("Official Bank Documents", [
                {"key": "Annual Tax Statement 2025", "val": "PDF Available"},
                {"key": "Account Verification Letter", "val": "Download"},
                {"key": "FINMA Deposit Guarantee", "val": "Certificate PDF"},
              ]);
            }),
            _buildMenuTile(Icons.help_outline_rounded, "Support & Help Center", "24/7 Swiss Banking Support Ticket Center", () {
              _openSimpleInfoSheet("Swiss Banking Support", [
                {"key": "Direct Helpline", "val": "+41 22 518 00 00"},
                {"key": "Email Support", "val": "support@neonfinswiss.world"},
                {"key": "Ticket Status", "val": "No Open Tickets"},
              ]);
            }),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  await ApiService.clearUserSession();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text("Log Out of Banking Session", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
