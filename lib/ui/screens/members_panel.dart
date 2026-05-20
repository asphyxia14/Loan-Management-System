import 'package:flutter/cupertino.dart';

import '../../models/app_models.dart';
import '../widgets/app_section_card.dart';

class MembersPanel extends StatelessWidget {
  const MembersPanel({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.searchController,
    required this.members,
    required this.onCreateMember,
    required this.onEditMember,
    required this.onToggleMemberStatus,
    required this.onDeleteMember,
    required this.formatMoney,
    required this.onSearchChanged,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController addressController;
  final TextEditingController searchController;
  final List<MemberRecord> members;
  final VoidCallback onCreateMember;
  final ValueChanged<MemberRecord> onEditMember;
  final ValueChanged<MemberRecord> onToggleMemberStatus;
  final ValueChanged<MemberRecord> onDeleteMember;
  final String Function(double) formatMoney;
  final ValueChanged<String> onSearchChanged;

  Widget _field(String label, TextEditingController controller, String placeholder, {VoidCallback? onSubmitted}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          onSubmitted: (_) => onSubmitted?.call(),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, {double? width}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(
          color: CupertinoColors.secondaryLabel,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget registerCard = AppSectionCard(
      title: 'Register Member',
      icon: CupertinoIcons.person_crop_circle_badge_plus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _field('FULL NAME', nameController, 'Enter full name', onSubmitted: onCreateMember),
          const SizedBox(height: 16),
          _field('PHONE NUMBER', phoneController, 'Enter phone number', onSubmitted: onCreateMember),
          const SizedBox(height: 16),
          _field('ADDRESS', addressController, 'Enter address', onSubmitted: onCreateMember),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.topLeft,
            child: CupertinoButton.filled(
              onPressed: onCreateMember,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(CupertinoIcons.person_add_solid, size: 18),
                  SizedBox(width: 8),
                  Text('Add Member'),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final Widget registryCard = AppSectionCard(
      title: 'Member Registry',
      subtitle: '${members.length} member(s)',
      icon: CupertinoIcons.person_2_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CupertinoSearchTextField(
              controller: searchController,
              onChanged: onSearchChanged,
              placeholder: 'Search name, member no, or phone...',
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          members.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No members found.'),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.tertiarySystemFill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: <Widget>[
                            _headerCell('Member No.', width: 110),
                            _headerCell('Full Name', width: 180),
                            _headerCell('Phone', width: 130),
                            _headerCell('Address', width: 170),
                            _headerCell('Status', width: 90),
                            _headerCell('Savings', width: 100),
                            _headerCell('Actions', width: 220),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List<Widget>.generate(members.length, (int index) {
                        return _MemberTableRow(
                          member: members[index],
                          index: index,
                          formatMoney: formatMoney,
                          onEditMember: onEditMember,
                          onToggleMemberStatus: onToggleMemberStatus,
                          onDeleteMember: onDeleteMember,
                        );
                      }),
                    ],
                  ),
                ),
        ],
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool useTwoColumns = constraints.maxWidth >= 1000;

          if (useTwoColumns) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 2, child: registerCard),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: registryCard),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              registerCard,
              const SizedBox(height: 10),
              Container(height: 1, color: CupertinoColors.separator),
              const SizedBox(height: 10),
              registryCard,
            ],
          );
        },
      ),
    );
  }
}

class _MemberTableRow extends StatefulWidget {
  const _MemberTableRow({
    required this.member,
    required this.index,
    required this.formatMoney,
    required this.onEditMember,
    required this.onToggleMemberStatus,
    required this.onDeleteMember,
  });

  final MemberRecord member;
  final int index;
  final String Function(double) formatMoney;
  final ValueChanged<MemberRecord> onEditMember;
  final ValueChanged<MemberRecord> onToggleMemberStatus;
  final ValueChanged<MemberRecord> onDeleteMember;

  @override
  State<_MemberTableRow> createState() => _MemberTableRowState();
}

class _MemberTableRowState extends State<_MemberTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.member.status.toUpperCase() == 'ACTIVE';
    final bool isEven = widget.index % 2 == 0;

    Color backgroundColor = isEven
        ? CupertinoColors.secondarySystemGroupedBackground
        : CupertinoColors.systemGrey6.withValues(alpha: 0.3);

    if (_isHovered) {
      backgroundColor = CupertinoColors.activeBlue.withValues(alpha: 0.1);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => widget.onEditMember(widget.member),
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: <Widget>[
              _cell(widget.member.memberNumber, width: 110),
              _cell(widget.member.fullName, width: 180, bold: true),
              _cell(
                widget.member.phoneNumber.isEmpty ? '-' : widget.member.phoneNumber,
                width: 130,
              ),
              _cell(
                widget.member.addressLine.isEmpty ? '-' : widget.member.addressLine,
                width: 170,
              ),
              SizedBox(
                width: 90,
                child: Text(
                  widget.member.status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                  ),
                ),
              ),
              _cell(
                widget.formatMoney(widget.member.savingsBalance),
                width: 100,
              ),
              SizedBox(
                width: 220,
                child: Row(
                  children: <Widget>[
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      onPressed: () => widget.onEditMember(widget.member),
                      child: const Icon(CupertinoIcons.pencil, size: 20),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      onPressed: () => widget.onToggleMemberStatus(widget.member),
                      child: Text(
                        isActive ? 'Set Inactive' : 'Set Active',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      onPressed: () => widget.onDeleteMember(widget.member),
                      child: const Icon(
                        CupertinoIcons.delete,
                        color: CupertinoColors.systemRed,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {double? width, bool bold = false}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}