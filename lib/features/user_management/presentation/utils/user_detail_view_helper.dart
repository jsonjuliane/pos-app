import 'package:flutter/material.dart';
import '../../../auth/data/models/app_user.dart';
import '../widgets/user_detail_panel.dart';

class UserDetailViewHelper {
  static void show(BuildContext context, AppUser user) {
    final width = MediaQuery.of(context).size.width;

    if (width < 600) {
      // 🔹 Mobile: Bottom Sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => UserDetailPanel(uid: user.uid),
      );
    } else if (width < 900) {
      // 🔸 Tablet: Dialog
      showDialog(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: UserDetailPanel(uid: user.uid),
          ),
        ),
      );
    } else {
      // 🖥️ Desktop/Web: Right-side drawer
      showGeneralDialog(
        barrierDismissible: true,
        barrierLabel: 'User Details',
        context: context,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => Align(
          alignment: Alignment.centerRight,
          child: Material(
            elevation: 12,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: UserDetailPanel(uid: user.uid),
            ),
          ),
        ),
        transitionBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: anim,
            curve: Curves.easeInOut,
          )),
          child: child,
        ),
      );
    }
  }
}