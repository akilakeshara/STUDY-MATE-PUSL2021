import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StudyMateFundingScreen extends StatefulWidget {
  const StudyMateFundingScreen({super.key});

  @override
  State<StudyMateFundingScreen> createState() => _StudyMateFundingScreenState();
}

class _StudyMateFundingScreenState extends State<StudyMateFundingScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNumberController =
      TextEditingController();
  final TextEditingController _bankAccountHolderController =
      TextEditingController();
  final TextEditingController _bankReferenceController =
      TextEditingController();
  final TextEditingController _walletProviderController =
      TextEditingController();
  final TextEditingController _walletNumberController = TextEditingController();
  final TextEditingController _walletHolderController = TextEditingController();

  String _selectedMethod = 'Card';
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _bankNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountHolderController.dispose();
    _bankReferenceController.dispose();
    _walletProviderController.dispose();
    _walletNumberController.dispose();
    _walletHolderController.dispose();
    super.dispose();
  }

  Future<void> _startFundingPayment() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid funding amount.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedMethod == 'Card') {
      final String cardNumber = _cardNumberController.text
          .replaceAll(' ', '')
          .trim();
      final String cardHolder = _cardHolderController.text.trim();
      final String expiry = _expiryController.text.trim();
      final String cvv = _cvvController.text.trim();

      if (cardNumber.length < 16 ||
          cardHolder.isEmpty ||
          expiry.length < 5 ||
          cvv.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete card details.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (_selectedMethod == 'Bank Transfer') {
      final String bankName = _bankNameController.text.trim();
      final String accountNumber = _bankAccountNumberController.text.trim();
      final String accountHolder = _bankAccountHolderController.text.trim();

      if (bankName.isEmpty ||
          accountNumber.length < 8 ||
          accountHolder.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete bank transfer details.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (_selectedMethod == 'Mobile Wallet') {
      final String provider = _walletProviderController.text.trim();
      final String walletNumber = _walletNumberController.text.trim();
      final String walletHolder = _walletHolderController.text.trim();

      if (provider.isEmpty || walletNumber.length < 8 || walletHolder.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete mobile wallet details.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? <String, dynamic>{};

      final fundingRef = FirebaseFirestore.instance
          .collection('study_mate_funding_payments')
          .doc();

      await fundingRef.set({
        'paymentId': fundingRef.id,
        'sponsorUid': user.uid,
        'sponsorName':
            (userData['firstName'] ?? userData['fullName'] ?? 'Sponsor')
                .toString()
                .trim(),
        'sponsorID':
            (userData['sponsorID'] ??
                    userData['sponsorData']?['sponsorID'] ??
                    '')
                .toString()
                .trim(),
        'email': (userData['email'] ?? user.email ?? '').toString().trim(),
        'amountLkr': amount,
        'currency': 'LKR',
        'method': _selectedMethod,
        'gatewayMode': 'simulated',
        'note': _noteController.text.trim(),
        'gateway': 'Study Mate Secure Gateway',
        'isRealCharge': false,
        'cardLast4': _selectedMethod == 'Card'
            ? _cardNumberController.text
                  .replaceAll(' ', '')
                  .substring(
                    _cardNumberController.text.replaceAll(' ', '').length - 4,
                  )
            : null,
        'cardHolder': _selectedMethod == 'Card'
            ? _cardHolderController.text.trim()
            : null,
        'bankTransferBankName': _selectedMethod == 'Bank Transfer'
            ? _bankNameController.text.trim()
            : null,
        'bankTransferAccountNumber': _selectedMethod == 'Bank Transfer'
            ? _bankAccountNumberController.text.trim()
            : null,
        'bankTransferAccountHolder': _selectedMethod == 'Bank Transfer'
            ? _bankAccountHolderController.text.trim()
            : null,
        'bankTransferReference': _selectedMethod == 'Bank Transfer'
            ? _bankReferenceController.text.trim()
            : null,
        'walletProvider': _selectedMethod == 'Mobile Wallet'
            ? _walletProviderController.text.trim()
            : null,
        'walletNumber': _selectedMethod == 'Mobile Wallet'
            ? _walletNumberController.text.trim()
            : null,
        'walletHolder': _selectedMethod == 'Mobile Wallet'
            ? _walletHolderController.text.trim()
            : null,
        'status': 'gateway_initiated',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      final bool? paid = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Secure Payment Gateway'),
          content: Text(
            'Proceed payment authorization for LKR ${amount.toStringAsFixed(2)} using $_selectedMethod?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );

      if (paid == true) {
        await fundingRef.update({
          'status': 'simulated_paid',
          'simulatedPaidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseFirestore.instance.collection('admin_notifications').add({
          'type': 'funding_paid',
          'title': 'New Funding Received',
          'message':
              '${(userData['firstName'] ?? userData['fullName'] ?? 'Sponsor').toString().trim()} paid LKR ${amount.toStringAsFixed(2)}.',
          'paymentId': fundingRef.id,
          'sponsorUid': user.uid,
          'amountLkr': amount,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Funding Confirmed'),
            content: Text(
              'Thank you! Payment ID: ${fundingRef.id}\n\nNo real money was deducted. This is a simulated gateway flow.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        await fundingRef.update({
          'status': 'simulated_cancelled',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FD),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Fund Study Mate',
          style: TextStyle(
            color: Color(0xFF1A1C2E),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE9EEFF)),
              ),
              child: const Text(
                'Support the Study Mate platform through a secure payment flow simulation. This looks like a real gateway process, but no real money is deducted.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF616A89),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildLabel('Funding Amount (LKR)'),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration('Ex: 2500'),
            ),
            const SizedBox(height: 14),
            _buildLabel('Payment Method'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _methodChip('Card'),
                _methodChip('Bank Transfer'),
                _methodChip('Mobile Wallet'),
              ],
            ),
            if (_selectedMethod == 'Card') ...[
              const SizedBox(height: 14),
              _buildLabel('Card Number'),
              const SizedBox(height: 8),
              TextField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _CardNumberFormatter(),
                ],
                decoration: _inputDecoration('1234 5678 9012 3456'),
              ),
              const SizedBox(height: 14),
              _buildLabel('Card Holder Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _cardHolderController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Name on card'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Expiry (MM/YY)'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _expiryController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9/]'),
                            ),
                            LengthLimitingTextInputFormatter(5),
                          ],
                          decoration: _inputDecoration('08/29'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('CVV'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: _inputDecoration('123'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (_selectedMethod == 'Bank Transfer') ...[
              const SizedBox(height: 14),
              _buildLabel('Bank Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _bankNameController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Commercial Bank'),
              ),
              const SizedBox(height: 14),
              _buildLabel('Account Number'),
              const SizedBox(height: 8),
              TextField(
                controller: _bankAccountNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(20),
                ],
                decoration: _inputDecoration('1234567890'),
              ),
              const SizedBox(height: 14),
              _buildLabel('Account Holder Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _bankAccountHolderController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Name on bank account'),
              ),
              const SizedBox(height: 14),
              _buildLabel('Transfer Reference (Optional)'),
              const SizedBox(height: 8),
              TextField(
                controller: _bankReferenceController,
                decoration: _inputDecoration('TRX-2026-001'),
              ),
            ],
            if (_selectedMethod == 'Mobile Wallet') ...[
              const SizedBox(height: 14),
              _buildLabel('Wallet Provider'),
              const SizedBox(height: 8),
              TextField(
                controller: _walletProviderController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('eZ Cash / mCash / Genie'),
              ),
              const SizedBox(height: 14),
              _buildLabel('Wallet Number'),
              const SizedBox(height: 8),
              TextField(
                controller: _walletNumberController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                decoration: _inputDecoration('07XXXXXXXX'),
              ),
              const SizedBox(height: 14),
              _buildLabel('Wallet Holder Name'),
              const SizedBox(height: 8),
              TextField(
                controller: _walletHolderController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration('Registered wallet name'),
              ),
            ],
            const SizedBox(height: 14),
            _buildLabel('Note (Optional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: _inputDecoration('Add any note for admin...'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _startFundingPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5C71D1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.payments_rounded, color: Colors.white),
                label: Text(
                  _isLoading ? 'Processing...' : 'Confirm ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF1A1C2E),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _methodChip(String method) {
    final bool selected = _selectedMethod == method;
    return ChoiceChip(
      label: Text(method),
      selected: selected,
      onSelected: (_) => setState(() => _selectedMethod = method),
      selectedColor: const Color(0xFF5C71D1).withOpacity(0.15),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? const Color(0xFF5C71D1) : const Color(0xFFE9EEFF),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF5C71D1) : const Color(0xFF64748B),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9EEFF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE9EEFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5C71D1)),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final String trimmed = digitsOnly.length > 16
        ? digitsOnly.substring(0, 16)
        : digitsOnly;

    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < trimmed.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(trimmed[i]);
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
