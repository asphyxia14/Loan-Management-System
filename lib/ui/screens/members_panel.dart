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
              : LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    if (constraints.maxWidth < 720) {
                      return Column(
                        children: members
                            .map((MemberRecord member) => _MemberSummaryCard(
                                  member: member,
                                  formatMoney: formatMoney,
                                  onEditMember: onEditMember,
                                  onToggleMemberStatus: onToggleMemberStatus,
                                  onDeleteMember: onDeleteMember,
                                ))
                            .toList(growable: false),
                      );
                    }

                    return SingleChildScrollView(
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
                    );
                  },
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

class _MemberTableRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final bool isActive = member.status.toUpperCase() == 'ACTIVE';
    final bool isEven = index % 2 == 0;

    final Color backgroundColor = isEven
        ? CupertinoColors.secondarySystemGroupedBackground
        : CupertinoColors.systemGrey6.withValues(alpha: 0.3);

    return GestureDetector(
      onTap: () => onEditMember(member),
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
            _cell(member.memberNumber, width: 110),
            _cell(member.fullName, width: 180, bold: true),
            _cell(
              member.phoneNumber.isEmpty ? '-' : member.phoneNumber,
              width: 130,
            ),
            _cell(
              member.addressLine.isEmpty ? '-' : member.addressLine,
              width: 170,
            ),
            _cell(member.status, width: 90),
            _cell(
              formatMoney(member.savingsBalance),
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
                    onPressed: () => onEditMember(member),
                    child: const Icon(CupertinoIcons.pencil, size: 20),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    onPressed: () => onToggleMemberStatus(member),
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
                    onPressed: () => onDeleteMember(member),
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

class _MemberSummaryCard extends StatefulWidget {
  const _MemberSummaryCard({
    required this.member,
    required this.formatMoney,
    required this.onEditMember,
    required this.onToggleMemberStatus,
    required this.onDeleteMember,
  });

  final MemberRecord member;
  final String Function(double) formatMoney;
  final ValueChanged<MemberRecord> onEditMember;
  final ValueChanged<MemberRecord> onToggleMemberStatus;
  final ValueChanged<MemberRecord> onDeleteMember;

  @override
  State<_MemberSummaryCard> createState() => _MemberSummaryCardState();
}

class _MemberSummaryCardState extends State<_MemberSummaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isActive = widget.member.status.toUpperCase() == 'ACTIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CupertinoButton(
            padding: const EdgeInsets.all(12),
            onPressed: () {
              setState(() {
                _expanded = !_expanded;
              });
            },
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.member.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? CupertinoColors.activeBlue.withValues(alpha: 0.1)
                                  : CupertinoColors.systemRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.member.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isActive ? CupertinoColors.activeBlue : CupertinoColors.systemRed,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey5,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Bal: ${widget.formatMoney(widget.member.savingsBalance)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  _expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                  color: CupertinoColors.secondaryLabel,
                  size: 16,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(height: 1, color: CupertinoColors.separator),
                  const SizedBox(height: 8),
                  Text('Member No: ${widget.member.memberNumber}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
                  const SizedBox(height: 4),
                  Text('Phone: ${widget.member.phoneNumber.isEmpty ? '-' : widget.member.phoneNumber}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
                  const SizedBox(height: 4),
                  Text('Address: ${widget.member.addressLine.isEmpty ? '-' : widget.member.addressLine}', style: const TextStyle(fontSize: 13, color: CupertinoColors.label)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        onPressed: () => widget.onEditMember(widget.member),
                        child: const Icon(CupertinoIcons.pencil, size: 20),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        onPressed: () => widget.onToggleMemberStatus(widget.member),
                        child: Text(isActive ? 'Set Inactive' : 'Set Active', style: const TextStyle(fontSize: 13)),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        onPressed: () => widget.onDeleteMember(widget.member),
                        child: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
