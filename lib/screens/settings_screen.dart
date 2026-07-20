import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/backup_service.dart';
import '../services/settings_service.dart';
import '../utils/currency_utils.dart';
import '../utils/validators.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final BackupService _backupService = BackupService();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();

  String _currencyCode = 'USD';
  Uint8List? _logoBytes;
  bool _initialized = false;
  bool _saving = false;
  bool _busy = false;

  void _initFromSettings(SettingsService settings) {
    if (_initialized) return;
    _nameCtrl.text = settings.companyName;
    _addressCtrl.text = settings.companyAddress;
    _emailCtrl.text = settings.companyEmail;
    _phoneCtrl.text = settings.companyPhone;
    _taxCtrl.text = settings.defaultTaxPercent == 0
        ? ''
        : settings.defaultTaxPercent.toString();
    _prefixCtrl.text = settings.invoicePrefix;
    _currencyCode = settings.currencyCode;
    _logoBytes = settings.logoBytes;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _taxCtrl.dispose();
    _prefixCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    // readAsBytes() works identically on Web and mobile — unlike
    // wrapping picked.path in a dart:io File, which only exists on
    // mobile/desktop.
    final bytes = await picked.readAsBytes();
    setState(() => _logoBytes = bytes);
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() => _saving = true);
    final settings = context.read<SettingsService>();
    await settings.saveCompanyDetails(
      companyName: _nameCtrl.text.trim(),
      companyAddress: _addressCtrl.text.trim(),
      companyEmail: _emailCtrl.text.trim(),
      companyPhone: _phoneCtrl.text.trim(),
      logoBytes: _logoBytes,
      currencyCode: _currencyCode,
      defaultTaxPercent: double.tryParse(_taxCtrl.text.trim()) ?? 0,
      invoicePrefix: _prefixCtrl.text.trim().isEmpty
          ? 'INV-'
          : _prefixCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _backup() async {
    setState(() => _busy = true);
    try {
      await _backupService.backupAndShare();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup ready to save/share')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
          'Pick a backup JSON file previously created with "Backup Data". '
          'Its invoices will be added to what\'s already in the app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Choose File'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final count = await _backupService.restoreFromFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restored $count invoice(s)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _busy = true);
    try {
      await _backupService.exportCsvAndShare();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV export ready to save/share')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV export failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    _initFromSettings(settings);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: AbsorbPointer(
        absorbing: _busy,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Form(
              key: _formKey,
              child: _SectionCard(
                icon: Icons.storefront_rounded,
                title: 'Company Details',
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickLogo,
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary.withOpacity(0.15),
                                  theme.colorScheme.secondary.withOpacity(0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: theme.colorScheme.primary
                                    .withOpacity(0.25),
                                width: 1.4,
                              ),
                            ),
                            child: _logoBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _logoBytes!,
                                      fit: BoxFit.cover,
                                      width: 96,
                                      height: 96,
                                    ),
                                  )
                                : Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: theme.cardColor, width: 2.5),
                              ),
                              child: const Icon(Icons.edit,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton(
                      onPressed: _pickLogo,
                      child: Text(
                        _logoBytes != null
                            ? 'Change Logo'
                            : 'Upload Company Logo',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Company name'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _currencyCode,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    items: kSupportedCurrencies
                        .map((c) => DropdownMenuItem(
                              value: c.code,
                              child: Text(
                                  '${c.code} (${c.symbol.trim()}) - ${c.name}'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _currencyCode = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _taxCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Default Tax Percentage (%)',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.percentage,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _prefixCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Prefix',
                      hintText: 'e.g. INV-',
                      prefixIcon: Icon(Icons.tag),
                    ),
                    validator: (v) =>
                        Validators.required(v, fieldName: 'Invoice prefix'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.palette_outlined,
              title: 'Appearance',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  value: settings.darkMode,
                  onChanged: (value) => settings.setDarkMode(value),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              icon: Icons.folder_outlined,
              title: 'Data',
              children: [
                _DataTile(
                  icon: Icons.backup_outlined,
                  title: 'Backup Data',
                  subtitle: 'Export all invoices as a JSON file',
                  onTap: _backup,
                ),
                _DataTile(
                  icon: Icons.restore_outlined,
                  title: 'Restore Data',
                  subtitle: 'Restore invoices from a backup file',
                  onTap: _restore,
                ),
                _DataTile(
                  icon: Icons.table_view_outlined,
                  title: 'Export Invoice List as CSV',
                  subtitle: 'Spreadsheet-friendly export',
                  onTap: _exportCsv,
                  showDivider: false,
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}

class _DataTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _DataTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: onTap,
        ),
        if (showDivider) const Divider(height: 4),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
