import 'package:flutter/cupertino.dart';

import '../data/coop_database_service.dart';
import '../models/app_models.dart';
import 'screens/connection_panel.dart';
import 'screens/dashboard_panel.dart';
import 'screens/loans_panel.dart';
import 'screens/members_panel.dart';
import 'screens/reports_panel.dart';
import 'screens/savings_panel.dart';

class CoopHomePage extends StatefulWidget {
  const CoopHomePage({super.key});

  @override
  State<CoopHomePage> createState() => _CoopHomePageState();
}

class _CoopHomePageState extends State<CoopHomePage> {
  final CoopDatabaseService _service = CoopDatabaseService();

  OverlayEntry? _toastEntry;

  final TextEditingController _apiBaseUrlController = TextEditingController(
    text: 'http://127.0.0.1:8080',
  );
  final TextEditingController _hostController = TextEditingController(
    text: '127.0.0.1',
  );
  final TextEditingController _portController = TextEditingController(
    text: '1433',
  );
  final TextEditingController _databaseController = TextEditingController(
    text: 'PQRCooperative',
  );
  final TextEditingController _usernameController = TextEditingController(
    text: 'sa',
  );
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _memberNameController = TextEditingController();
  final TextEditingController _memberPhoneController = TextEditingController();
  final TextEditingController _memberAddressController =
      TextEditingController();

  final TextEditingController _savingsAmountController =
      TextEditingController();
  final TextEditingController _savingsReferenceController =
      TextEditingController();
  final TextEditingController _savingsRemarksController =
      TextEditingController();

  final TextEditingController _loanPrincipalController =
      TextEditingController();
  final TextEditingController _loanRateController = TextEditingController(
    text: '12',
  );
  final TextEditingController _loanTermMonthsController = TextEditingController(
    text: '12',
  );
  final TextEditingController _loanPurposeController = TextEditingController();
  final TextEditingController _loanApprovedByController = TextEditingController(
    text: 'Manager',
  );

  final TextEditingController _paymentPrincipalController =
      TextEditingController();
  final TextEditingController _paymentInterestController =
      TextEditingController();
  final TextEditingController _paymentPenaltyController = TextEditingController(
    text: '0',
  );
  final TextEditingController _paymentRemarksController =
      TextEditingController();

  int _selectedTab = 0;
  bool _isConnecting = false;
  bool _isLoadingCoreData = false;
  bool _isGeneratingReport = false;
  DateTime? _lastSyncTime;

  DashboardMetrics _dashboard = const DashboardMetrics(
    activeMembers: 0,
    totalSavings: 0,
    activeLoans: 0,
    totalLoanOutstanding: 0,
  );
  List<MemberRecord> _members = const <MemberRecord>[];
  List<LoanAccountRecord> _loans = const <LoanAccountRecord>[];

  int? _selectedSavingsMemberId;
  String _selectedSavingsTransactionType = 'DEPOSIT';
  List<SavingsTransactionRecord> _savingsHistory =
      const <SavingsTransactionRecord>[];
  double _selectedMemberSavingsBalance = 0;

  int? _selectedLoanMemberId;
  int? _selectedPaymentLoanId;
  List<LoanPaymentRecord> _loanPaymentHistory = const <LoanPaymentRecord>[];

  int _reportYear = DateTime.now().year;
  int _reportMonth = DateTime.now().month;
  MonthlyFinancialSummary? _reportSummary;

  List<MemberRecord> get _activeMembers {
    return _members
        .where((MemberRecord member) => member.status.toUpperCase() == 'ACTIVE')
        .toList(growable: false);
  }

  @override
  void dispose() {
    _toastEntry?.remove();

    _apiBaseUrlController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();

    _memberNameController.dispose();
    _memberPhoneController.dispose();
    _memberAddressController.dispose();

    _savingsAmountController.dispose();
    _savingsReferenceController.dispose();
    _savingsRemarksController.dispose();

    _loanPrincipalController.dispose();
    _loanRateController.dispose();
    _loanTermMonthsController.dispose();
    _loanPurposeController.dispose();
    _loanApprovedByController.dispose();

    _paymentPrincipalController.dispose();
    _paymentInterestController.dispose();
    _paymentPenaltyController.dispose();
    _paymentRemarksController.dispose();

    super.dispose();
  }

  Future<void> _connectAndInitialize() async {
    if (_isConnecting) {
      return;
    }

    setState(() {
      _isConnecting = true;
    });

    try {
      final bool connected = await _service.connect(
        DbConnectionConfig(
          apiBaseUrl: _apiBaseUrlController.text.trim(),
          host: _hostController.text.trim(),
          port: _portController.text.trim(),
          database: _databaseController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!connected) {
        throw StateError(
          'Could not connect to backend/SQL. Check API URL and SQL credentials.',
        );
      }

      await _service.initializeSchema();
      await _reloadCoreData();
      await _loadSelectedDetails();

      if (!mounted) {
        return;
      }
      _showNotice('Connected and schema synchronized.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showNotice('Connection failed: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  Future<void> _disconnect() async {
    await _service.disconnect();
    setState(() {
      _selectedTab = 0;
      _dashboard = const DashboardMetrics(
        activeMembers: 0,
        totalSavings: 0,
        activeLoans: 0,
        totalLoanOutstanding: 0,
      );
      _members = const <MemberRecord>[];
      _loans = const <LoanAccountRecord>[];
      _selectedSavingsMemberId = null;
      _selectedLoanMemberId = null;
      _selectedPaymentLoanId = null;
      _savingsHistory = const <SavingsTransactionRecord>[];
      _loanPaymentHistory = const <LoanPaymentRecord>[];
      _selectedMemberSavingsBalance = 0;
      _reportSummary = null;
      _lastSyncTime = null;
    });
  }

  Future<void> _reloadCoreData() async {
    if (!_service.isConnected) {
      return;
    }

    setState(() {
      _isLoadingCoreData = true;
    });

    try {
      final Future<DashboardMetrics> metricsFuture = _service
          .fetchDashboardMetrics();
      final Future<List<MemberRecord>> membersFuture = _service.fetchMembers();
      final Future<List<LoanAccountRecord>> loansFuture = _service.fetchLoans();

      final List<Object> results = await Future.wait<Object>(<Future<Object>>[
        metricsFuture,
        membersFuture,
        loansFuture,
      ]);

      final DashboardMetrics metrics = results[0] as DashboardMetrics;
      final List<MemberRecord> members = results[1] as List<MemberRecord>;
      final List<LoanAccountRecord> loans =
          results[2] as List<LoanAccountRecord>;

      if (!mounted) {
        return;
      }

      setState(() {
        _dashboard = metrics;
        _members = members;
        _loans = loans;
        _lastSyncTime = DateTime.now();
      });

      _synchronizeSelections();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCoreData = false;
        });
      }
    }
  }

  void _synchronizeSelections() {
    setState(() {
      final List<MemberRecord> activeMembers = _activeMembers;

      if (activeMembers.isEmpty) {
        _selectedSavingsMemberId = null;
        _selectedLoanMemberId = null;
      } else {
        final Set<int> memberIds = activeMembers
            .map((MemberRecord m) => m.memberId)
            .toSet();
        if (_selectedSavingsMemberId == null ||
            !memberIds.contains(_selectedSavingsMemberId)) {
          _selectedSavingsMemberId = activeMembers.first.memberId;
        }
        if (_selectedLoanMemberId == null ||
            !memberIds.contains(_selectedLoanMemberId)) {
          _selectedLoanMemberId = activeMembers.first.memberId;
        }
      }

      if (_loans.isEmpty) {
        _selectedPaymentLoanId = null;
      } else {
        final Set<int> loanIds = _loans
            .map((LoanAccountRecord l) => l.loanId)
            .toSet();
        if (_selectedPaymentLoanId == null ||
            !loanIds.contains(_selectedPaymentLoanId)) {
          _selectedPaymentLoanId = _loans.first.loanId;
        }
      }
    });
  }

  Future<void> _loadSelectedDetails() async {
    if (_selectedSavingsMemberId != null) {
      await _loadSavingsDetails(_selectedSavingsMemberId!);
    } else {
      setState(() {
        _savingsHistory = const <SavingsTransactionRecord>[];
        _selectedMemberSavingsBalance = 0;
      });
    }

    if (_selectedPaymentLoanId != null) {
      await _loadLoanPaymentDetails(_selectedPaymentLoanId!);
    } else {
      setState(() {
        _loanPaymentHistory = const <LoanPaymentRecord>[];
      });
    }
  }

  Future<void> _loadSavingsDetails(int memberId) async {
    final List<SavingsTransactionRecord> history = await _service
        .fetchSavingsTransactions(memberId: memberId);
    final double balance = await _service.fetchSavingsBalance(memberId);

    if (!mounted) {
      return;
    }
    setState(() {
      _savingsHistory = history;
      _selectedMemberSavingsBalance = balance;
    });
  }

  Future<void> _loadLoanPaymentDetails(int loanId) async {
    final List<LoanPaymentRecord> history = await _service.fetchLoanPayments(
      loanId: loanId,
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _loanPaymentHistory = history;
    });
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    required String actionText,
    bool isDestructive = false,
  }) async {
    final bool? confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(actionText),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _createMember() async {
    final String fullName = _memberNameController.text.trim();
    if (fullName.isEmpty) {
      _showNotice('Member name is required.', isError: true);
      return;
    }

    try {
      await _service.createMember(
        fullName: fullName,
        phoneNumber: _memberPhoneController.text.trim(),
        addressLine: _memberAddressController.text.trim(),
      );

      _memberNameController.clear();
      _memberPhoneController.clear();
      _memberAddressController.clear();

      await _reloadCoreData();
      await _loadSelectedDetails();

      if (!mounted) {
        return;
      }
      _showNotice('Member added successfully.');
    } catch (error) {
      _showNotice('Could not create member: $error', isError: true);
    }
  }

  Future<void> _toggleMemberStatus(MemberRecord member) async {
    final bool isActive = member.status.toUpperCase() == 'ACTIVE';
    final String targetStatus = isActive ? 'INACTIVE' : 'ACTIVE';

    final bool confirmed = await _confirmAction(
      title: isActive ? 'Set Member Inactive?' : 'Set Member Active?',
      message: isActive
          ? 'Inactive members cannot post new savings or loan transactions.'
          : 'This member will be allowed to post savings and loan transactions again.',
      actionText: 'Confirm',
    );

    if (!confirmed) {
      return;
    }

    try {
      await _service.updateMemberStatus(
        memberId: member.memberId,
        status: targetStatus,
      );

      await _reloadCoreData();
      await _loadSelectedDetails();

      if (!mounted) {
        return;
      }
      _showNotice(
        isActive ? 'Member set to INACTIVE.' : 'Member set to ACTIVE.',
      );
    } catch (error) {
      _showNotice('Could not update member status: $error', isError: true);
    }
  }

  Future<void> _deleteMember(MemberRecord member) async {
    final bool confirmed = await _confirmAction(
      title: 'Delete Member?',
      message:
          'This will permanently delete ${member.fullName} only if no savings or loan records exist.',
      actionText: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    try {
      await _service.deleteMember(member.memberId);
      await _reloadCoreData();
      await _loadSelectedDetails();

      if (!mounted) {
        return;
      }
      _showNotice('Member deleted successfully.');
    } catch (error) {
      _showNotice('Could not delete member: $error', isError: true);
    }
  }

  Future<void> _recordSavingsTransaction() async {
    final int? memberId = _selectedSavingsMemberId;
    final double? amount = double.tryParse(
      _savingsAmountController.text.trim(),
    );

    if (memberId == null) {
      _showNotice('Select a member first.', isError: true);
      return;
    }
    final bool isActiveMember = _activeMembers.any(
      (MemberRecord member) => member.memberId == memberId,
    );
    if (!isActiveMember) {
      _showNotice(
        'Savings transactions are allowed only for ACTIVE members.',
        isError: true,
      );
      return;
    }
    if (amount == null || amount <= 0) {
      _showNotice('Enter a valid amount greater than 0.', isError: true);
      return;
    }

    try {
      await _service.recordSavingsTransaction(
        memberId: memberId,
        transactionType: _selectedSavingsTransactionType,
        amount: amount,
        transactionDate: DateTime.now(),
        referenceNo: _savingsReferenceController.text.trim(),
        remarks: _savingsRemarksController.text.trim(),
      );

      _savingsAmountController.clear();
      _savingsReferenceController.clear();
      _savingsRemarksController.clear();

      await _reloadCoreData();
      await _loadSavingsDetails(memberId);

      if (!mounted) {
        return;
      }
      _showNotice('Savings transaction posted.');
    } catch (error) {
      _showNotice('Could not record transaction: $error', isError: true);
    }
  }

  Future<void> _createLoan() async {
    final int? memberId = _selectedLoanMemberId;
    final double? principal = double.tryParse(_loanPrincipalController.text);
    final double? rate = double.tryParse(_loanRateController.text);
    final int? term = int.tryParse(_loanTermMonthsController.text);

    if (memberId == null) {
      _showNotice('Select a member for the loan.', isError: true);
      return;
    }
    final bool isActiveMember = _activeMembers.any(
      (MemberRecord member) => member.memberId == memberId,
    );
    if (!isActiveMember) {
      _showNotice(
        'Loans can be created only for ACTIVE members.',
        isError: true,
      );
      return;
    }
    if (principal == null || principal <= 0) {
      _showNotice('Loan principal must be greater than 0.', isError: true);
      return;
    }
    if (rate == null || rate < 0) {
      _showNotice('Loan interest rate must be 0 or higher.', isError: true);
      return;
    }
    if (term == null || term <= 0) {
      _showNotice('Term months must be greater than 0.', isError: true);
      return;
    }

    try {
      final int newLoanId = await _service.createLoan(
        memberId: memberId,
        principalAmount: principal,
        annualInterestRate: rate,
        termMonths: term,
        purpose: _loanPurposeController.text.trim(),
        approvedBy: _loanApprovedByController.text.trim().isEmpty
            ? 'Manager'
            : _loanApprovedByController.text.trim(),
      );

      _loanPrincipalController.clear();
      _loanPurposeController.clear();

      await _reloadCoreData();
      setState(() {
        _selectedPaymentLoanId = newLoanId;
      });
      await _loadLoanPaymentDetails(newLoanId);

      if (!mounted) {
        return;
      }
      _showNotice('Loan created and approved.');
    } catch (error) {
      _showNotice('Could not create loan: $error', isError: true);
    }
  }

  Future<void> _recordLoanPayment() async {
    final int? loanId = _selectedPaymentLoanId;
    final double principalPaid =
        double.tryParse(_paymentPrincipalController.text.trim()) ?? 0;
    final double interestPaid =
        double.tryParse(_paymentInterestController.text.trim()) ?? 0;
    final double penaltyPaid =
        double.tryParse(_paymentPenaltyController.text.trim()) ?? 0;

    if (loanId == null) {
      _showNotice('Select a loan first.', isError: true);
      return;
    }
    final double totalPayment = principalPaid + interestPaid + penaltyPaid;
    if (totalPayment <= 0) {
      _showNotice('Total payment must be greater than 0.', isError: true);
      return;
    }

    LoanAccountRecord? selectedLoan;
    for (final LoanAccountRecord loan in _loans) {
      if (loan.loanId == loanId) {
        selectedLoan = loan;
        break;
      }
    }
    if (selectedLoan == null) {
      _showNotice(
        'Selected loan was not found. Refresh data and try again.',
        isError: true,
      );
      return;
    }
    if (selectedLoan.status.toUpperCase() != 'APPROVED') {
      _showNotice(
        'Payments can be posted only to APPROVED loans.',
        isError: true,
      );
      return;
    }
    if (totalPayment > selectedLoan.totalOutstanding + 0.005) {
      _showNotice(
        'Payment exceeds current outstanding balance (${_money(selectedLoan.totalOutstanding)}).',
        isError: true,
      );
      return;
    }

    try {
      await _service.recordLoanPayment(
        loanId: loanId,
        paymentDate: DateTime.now(),
        principalPaid: principalPaid,
        interestPaid: interestPaid,
        penaltyPaid: penaltyPaid,
        remarks: _paymentRemarksController.text.trim(),
      );

      _paymentPrincipalController.clear();
      _paymentInterestController.clear();
      _paymentPenaltyController.text = '0';
      _paymentRemarksController.clear();

      await _reloadCoreData();
      await _loadLoanPaymentDetails(loanId);

      if (!mounted) {
        return;
      }
      _showNotice('Loan payment posted.');
    } catch (error) {
      _showNotice('Could not record payment: $error', isError: true);
    }
  }

  Future<void> _generateMonthlyReport() async {
    setState(() {
      _isGeneratingReport = true;
    });

    try {
      final MonthlyFinancialSummary? summary = await _service
          .fetchMonthlySummary(year: _reportYear, month: _reportMonth);

      if (!mounted) {
        return;
      }
      setState(() {
        _reportSummary = summary;
      });
    } catch (error) {
      _showNotice('Could not load report: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingReport = false;
        });
      }
    }
  }

  void _showNotice(String message, {bool isError = false}) {
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);

    _toastEntry?.remove();

    final OverlayEntry entry = OverlayEntry(
      builder: (BuildContext context) {
        return Positioned(
          top: 80,
          left: 20,
          right: 20,
          child: Center(
            child: CupertinoPopupSurface(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isError
                      ? CupertinoColors.systemRed.withValues(alpha: 0.9)
                      : CupertinoColors.tertiarySystemBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? CupertinoColors.white
                        : CupertinoColors.label,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _toastEntry = entry;
    overlay.insert(entry);

    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      if (_toastEntry == entry) {
        entry.remove();
        _toastEntry = null;
      }
    });
  }

  void _handleSavingsMemberChanged(int? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _selectedSavingsMemberId = value;
    });
    _loadSavingsDetails(value);
  }

  void _handleSavingsTransactionTypeChanged(String? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _selectedSavingsTransactionType = value;
    });
  }

  void _handleLoanMemberChanged(int? value) {
    setState(() {
      _selectedLoanMemberId = value;
    });
  }

  void _handlePaymentLoanChanged(int? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _selectedPaymentLoanId = value;
    });
    _loadLoanPaymentDetails(value);
  }

  void _handleReportYearChanged(int? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _reportYear = value;
    });
  }

  void _handleReportMonthChanged(int? value) {
    if (value == null) {
      return;
    }
    setState(() {
      _reportMonth = value;
    });
  }

  String _formatTime(DateTime time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _panelTitle() {
    const List<String> labels = <String>[
      'Dashboard',
      'Members',
      'Savings',
      'Loans',
      'Reports',
    ];
    return labels[_selectedTab.clamp(0, labels.length - 1)];
  }

  String _panelStatus() {
    switch (_selectedTab) {
      case 0:
        return '${_dashboard.activeMembers} active members';
      case 1:
        return '${_activeMembers.length} active • ${_members.length} total';
      case 2:
        if (_selectedSavingsMemberId == null) {
          return 'Select a member to view balance';
        }
        return 'Balance ${_money(_selectedMemberSavingsBalance)}';
      case 3:
        return '${_loans.length} loans • ${_loanPaymentHistory.length} payments';
      case 4:
        return 'Period $_reportYear-${_reportMonth.toString().padLeft(2, '0')}';
      default:
        return '';
    }
  }

  Widget _panelHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _panelTitle(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _panelStatus(),
                  style: const TextStyle(
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          if (_lastSyncTime != null)
            Text(
              'Last synced ${_formatTime(_lastSyncTime!)}',
              style: const TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentPanel() {
    switch (_selectedTab) {
      case 0:
        return DashboardPanel(dashboard: _dashboard, formatMoney: _money);
      case 1:
        return MembersPanel(
          nameController: _memberNameController,
          phoneController: _memberPhoneController,
          addressController: _memberAddressController,
          members: _members,
          onCreateMember: _createMember,
          onToggleMemberStatus: _toggleMemberStatus,
          onDeleteMember: _deleteMember,
          formatMoney: _money,
        );
      case 2:
        return SavingsPanel(
          members: _activeMembers,
          selectedMemberId: _selectedSavingsMemberId,
          selectedTransactionType: _selectedSavingsTransactionType,
          amountController: _savingsAmountController,
          referenceController: _savingsReferenceController,
          remarksController: _savingsRemarksController,
          currentBalance: _selectedMemberSavingsBalance,
          history: _savingsHistory,
          onSelectMember: _handleSavingsMemberChanged,
          onSelectTransactionType: _handleSavingsTransactionTypeChanged,
          onSubmit: _recordSavingsTransaction,
          formatMoney: _money,
          formatDate: _formatDate,
        );
      case 3:
        return LoansPanel(
          members: _activeMembers,
          loans: _loans,
          selectedLoanMemberId: _selectedLoanMemberId,
          selectedPaymentLoanId: _selectedPaymentLoanId,
          loanPrincipalController: _loanPrincipalController,
          loanRateController: _loanRateController,
          loanTermMonthsController: _loanTermMonthsController,
          loanPurposeController: _loanPurposeController,
          loanApprovedByController: _loanApprovedByController,
          paymentPrincipalController: _paymentPrincipalController,
          paymentInterestController: _paymentInterestController,
          paymentPenaltyController: _paymentPenaltyController,
          paymentRemarksController: _paymentRemarksController,
          paymentHistory: _loanPaymentHistory,
          onSelectLoanMember: _handleLoanMemberChanged,
          onCreateLoan: _createLoan,
          onSelectPaymentLoan: _handlePaymentLoanChanged,
          onPostPayment: _recordLoanPayment,
          formatMoney: _money,
          formatDate: _formatDate,
        );
      case 4:
        return ReportsPanel(
          reportYear: _reportYear,
          reportMonth: _reportMonth,
          isGenerating: _isGeneratingReport,
          summary: _reportSummary,
          onYearChanged: _handleReportYearChanged,
          onMonthChanged: _handleReportMonthChanged,
          onGenerate: _generateMonthlyReport,
          formatMoney: _money,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSidebar(bool compact) {
    const List<String> labels = <String>[
      'Dashboard',
      'Members',
      'Savings',
      'Loans',
      'Reports',
    ];

    const List<IconData> icons = <IconData>[
      CupertinoIcons.chart_bar,
      CupertinoIcons.person_2,
      CupertinoIcons.money_dollar_circle,
      CupertinoIcons.creditcard,
      CupertinoIcons.doc_text,
    ];

    return Container(
      width: compact ? 80 : 220,
      color: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            const SizedBox(height: 8),
            const Text(
              'PQR',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: labels.length,
                itemBuilder: (BuildContext context, int index) {
                  final bool selected = _selectedTab == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _selectedTab = index;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? CupertinoColors.activeBlue.withValues(
                                  alpha: 0.16,
                                )
                              : CupertinoColors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: compact
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              icons[index],
                              color: selected
                                  ? CupertinoColors.activeBlue
                                  : CupertinoColors.secondaryLabel,
                            ),
                            if (!compact) ...<Widget>[
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  labels[index],
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: selected
                                        ? CupertinoColors.activeBlue
                                        : CupertinoColors.label,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                onPressed: _isLoadingCoreData
                    ? null
                    : () async {
                        await _reloadCoreData();
                        await _loadSelectedDetails();
                      },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      CupertinoIcons.refresh,
                      color: _isLoadingCoreData
                          ? CupertinoColors.inactiveGray
                          : CupertinoColors.activeBlue,
                    ),
                    if (!compact) ...<Widget>[
                      const SizedBox(width: 8),
                      const Text('Refresh'),
                    ],
                  ],
                ),
              ),
            ),
            if (!compact && _lastSyncTime != null)
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 2, right: 10),
                child: Text(
                  'Last sync ${_formatTime(_lastSyncTime!)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                onPressed: _disconnect,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(CupertinoIcons.square_arrow_right),
                    if (!compact) ...<Widget>[
                      const SizedBox(width: 8),
                      const Text('Disconnect'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_service.isConnected) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('PQR Cooperative'),
        ),
        child: SafeArea(
          child: ConnectionPanel(
            apiBaseUrlController: _apiBaseUrlController,
            hostController: _hostController,
            portController: _portController,
            databaseController: _databaseController,
            usernameController: _usernameController,
            passwordController: _passwordController,
            isConnecting: _isConnecting,
            onConnect: _connectAndInitialize,
          ),
        ),
      );
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('PQR Cooperative'),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool compactSidebar = constraints.maxWidth < 1100;

            return Row(
              children: <Widget>[
                _buildSidebar(compactSidebar),
                Container(width: 1, color: CupertinoColors.separator),
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemGroupedBackground,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _panelHeader(),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Container(
                                height: 1,
                                color: CupertinoColors.separator,
                              ),
                            ),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder:
                                    (Widget child, Animation<double> anim) {
                                  final Animation<Offset> offset =
                                      Tween<Offset>(
                                    begin: const Offset(0.02, 0),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: anim,
                                      curve: Curves.easeOutCubic,
                                    ),
                                  );
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: offset,
                                      child: child,
                                    ),
                                  );
                                },
                                child: SizedBox(
                                  key: ValueKey<int>(_selectedTab),
                                  width: double.infinity,
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: _buildCurrentPanel(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isLoadingCoreData)
                        const Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: CupertinoActivityIndicator(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _money(double amount) {
    return amount.toStringAsFixed(2);
  }

  String _formatDate(DateTime date) {
    final String year = date.year.toString().padLeft(4, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
