import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  String _selectedNetwork = 'MTN MoMo';
  bool _loading = true;
  bool _saving = false;

  static const _networks = ['MTN MoMo', 'Vodafone Cash', 'AirtelTigo'];

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadPayout();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _loadPayout() async {
    final doc = await FirebaseFirestore.instance
        .collection('riders')
        .doc(_uid)
        .get();
    final p = doc.data()?['payout'] as Map<String, dynamic>?;
    if (p != null && mounted) {
      _nameController.text = p['accountName'] ?? '';
      _numberController.text = p['accountNumber'] ?? '';
      _selectedNetwork = p['network'] ?? 'MTN MoMo';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('riders')
          .doc(_uid)
          .update({
        'payout': {
          'network': _selectedNetwork,
          'accountName': _nameController.text.trim(),
          'accountNumber': _numberController.text.trim(),
        }
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payout details saved'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payout Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFFC107)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined,
                              color: Color(0xFFFFC107)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Earnings are paid out weekly to your mobile money account.',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Mobile Money Network',
                        style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    const SizedBox(height: 12),
                    Row(
                      children: _networks.map((n) {
                        final selected = _selectedNetwork == n;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedNetwork = n),
                            child: Container(
                              margin: EdgeInsets.only(
                                  right: n != _networks.last ? 8 : 0),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFC107)
                                        .withValues(alpha: 0.15)
                                    : const Color(0xFF1E1E1E),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFFC107)
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(n,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: selected
                                          ? const Color(0xFFFFC107)
                                          : Colors.white54,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    _field(_nameController, 'Account Name',
                        Icons.person_outline),
                    const SizedBox(height: 14),
                    _field(_numberController, 'Mobile Money Number',
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC107),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2))
                          : const Text('Save Payout Details',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFFC107)),
        ),
      ),
    );
  }
}
