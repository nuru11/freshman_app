import 'package:flutter/material.dart';
import 'package:vector_academy/config/app_config.dart';
import 'package:get/get.dart';
import 'package:vector_academy/controllers/controllers.dart';
import 'package:vector_academy/components/components.dart';

class AddPlanPage extends StatelessWidget {
  const AddPlanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddPlanController>(
      builder: (controller) => FreshmanPageScaffold(
        title: controller.plan == null
            ? 'Create Study Plan'
            : 'Edit Study Plan',
        subtitle: 'Schedule a study block',
        body: const _AddPlanForm(),
      ),
    );
  }
}

class _AddPlanForm extends StatelessWidget {
  const _AddPlanForm();

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: FreshmanSurfaceCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            Icon(Icons.chevron_right_rounded, color: secondaryColor),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddPlanController>(
      builder: (controller) => Form(
        key: controller.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: controller.titleController,
                enabled: !controller.isSubmitting,
                decoration: _fieldDecoration(
                  label: 'Title *',
                  hint: 'e.g., Review Math Chapter 5',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                autofocus: controller.plan == null,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.descriptionController,
                enabled: !controller.isSubmitting,
                decoration: _fieldDecoration(
                  label: 'Description',
                  hint: 'Add notes or details...',
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller.subjectController,
                enabled: !controller.isSubmitting,
                decoration: _fieldDecoration(
                  label: subjectLabel,
                  hint: 'e.g., Mathematics',
                  prefixIcon: Icon(Icons.menu_book_rounded, color: primaryColor),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Text(
                'Schedule',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onSurfaceColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: controller.isSubmitting ? 0.6 : 1.0,
                child: _pickerTile(
                  icon: Icons.calendar_today_rounded,
                  iconBg: primaryColor.withValues(alpha: 0.1),
                  iconColor: primaryColor,
                  label: 'Date (Optional)',
                  value: controller.selectedDate != null
                      ? '${controller.getDayOfWeek(controller.selectedDate!)}, ${controller.selectedDate!.day}/${controller.selectedDate!.month}/${controller.selectedDate!.year}'
                      : 'No date set',
                  valueColor: controller.selectedDate != null
                      ? onSurfaceColor
                      : onSurfaceVariant,
                  onTap: controller.isSubmitting
                      ? null
                      : () => controller.selectDate(context),
                  trailing: controller.selectedDate != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          color: onSurfaceVariant,
                          onPressed: controller.isSubmitting
                              ? null
                              : controller.clearDate,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: controller.isSubmitting ? 0.6 : 1.0,
                child: _pickerTile(
                  icon: Icons.play_arrow_rounded,
                  iconBg: primaryColor.withValues(alpha: 0.08),
                  iconColor: primaryColor,
                  label: 'Start Time *',
                  value: controller.startTime != null
                      ? '${controller.startTime!.hour.toString().padLeft(2, '0')}:${controller.startTime!.minute.toString().padLeft(2, '0')}'
                      : controller.selectedDate != null
                          ? 'Required'
                          : 'No start time set',
                  valueColor: controller.startTime != null
                      ? onSurfaceColor
                      : controller.selectedDate != null
                          ? secondaryColor
                          : onSurfaceVariant,
                  onTap: controller.isSubmitting
                      ? null
                      : () => controller.selectStartTime(context),
                ),
              ),
              const SizedBox(height: 10),
              Opacity(
                opacity: controller.isSubmitting ? 0.6 : 1.0,
                child: _pickerTile(
                  icon: Icons.stop_rounded,
                  iconBg: secondaryColor.withValues(alpha: 0.1),
                  iconColor: secondaryColor,
                  label: 'End Time *',
                  value: controller.endTime != null
                      ? '${controller.endTime!.hour.toString().padLeft(2, '0')}:${controller.endTime!.minute.toString().padLeft(2, '0')}'
                      : controller.selectedDate != null
                          ? 'Required'
                          : 'No end time set',
                  valueColor: controller.endTime != null
                      ? onSurfaceColor
                      : controller.selectedDate != null
                          ? secondaryColor
                          : onSurfaceVariant,
                  onTap: controller.isSubmitting
                      ? null
                      : () => controller.selectEndTime(context),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Repeat',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onSurfaceColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select days of the week to repeat this plan',
                style: TextStyle(fontSize: 13, color: onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              FreshmanSurfaceCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected =
                        controller.selectedDays.contains(day);
                    return GestureDetector(
                      onTap: controller.isSubmitting
                          ? null
                          : () => controller.toggleDay(day),
                      child: Opacity(
                        opacity: controller.isSubmitting ? 0.6 : 1.0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor
                                : backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  isSelected ? primaryColor : borderColor,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              controller.dayNames[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (controller.selectedDays.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.repeat_rounded, size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Repeats on: ${controller.selectedDays.map((d) => controller.dayNames[d - 1]).join(', ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed:
                    controller.isSubmitting ? null : controller.savePlan,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: onSurfaceVariant,
                ),
                child: controller.isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        controller.plan == null
                            ? 'Create Plan'
                            : 'Update Plan',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
