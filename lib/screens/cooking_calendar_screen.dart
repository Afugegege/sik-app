import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/cooking_record.dart';
import '../models/cooking_reminder.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class CookingCalendarScreen extends StatefulWidget {
  const CookingCalendarScreen({super.key});

  @override
  State<CookingCalendarScreen> createState() => _CookingCalendarScreenState();
}

class _CookingCalendarScreenState extends State<CookingCalendarScreen> with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late TabController _tabController;
  String _selectedReminderFilter = 'All';

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  void _showAddRecordDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    int rating = 5;
    String photoUrl = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: appState.bgPrimary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Record Cooked Meal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick recipe selector chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: appState.recipes.take(5).map((r) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(
                                r.title,
                                style: GoogleFonts.plusJakartaSans(fontSize: 11),
                              ),
                              onPressed: () {
                                setModalState(() {
                                  titleController.text = r.title;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Dish Title Input
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Dish Name',
                        hintText: 'e.g. Kimchi Fried Rice, Tofu Stew',
                        filled: true,
                        fillColor: AppTheme.bgSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: appState.bgSubtle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Star Rating Picker
                    Row(
                      children: [
                        Text(
                          'Rating:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...List.generate(5, (index) {
                          final star = index + 1;
                          return IconButton(
                            iconSize: 24,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setModalState(() => rating = star);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Notes Input
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Cooking Notes',
                        hintText: 'How did it taste? Any substitutions made?',
                        filled: true,
                        fillColor: AppTheme.bgSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: appState.bgSubtle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const SizedBox(height: 14),

                    // Cooked Meal Photo Attacher UI
                    if (photoUrl.isNotEmpty) ...[
                      // Attached Photo Preview Card with Quick Actions
                      Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: appState.bgSubtle),
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => Container(
                                  color: appState.bgCard,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, size: 32, color: AppTheme.textLight),
                                  ),
                                ),
                              ),
                            ),
                            // Gradient bottom shade
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.65),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Status Pill
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Photo Attached',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Action Buttons (Change & Delete)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Row(
                                children: [
                                  Material(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        setModalState(() => photoUrl = '');
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Photo Attacher Selector
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.bgSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: appState.bgSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.add_a_photo_outlined, size: 16, color: accentColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Cooked Meal Photo',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textMain,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Action buttons: Snap Photo & From Gallery
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      // Simulated instant camera snapshot
                                      setModalState(() {
                                        photoUrl = 'https://images.unsplash.com/photo-1596560548464-f010549b84d7?w=600&q=80';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Captured food snapshot!'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_outlined, size: 15, color: accentColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Snap Photo',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: accentColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      // Pick from device gallery
                                      setModalState(() {
                                        photoUrl = 'https://images.unsplash.com/photo-1583032015879-6617a26f32e9?w=600&q=80';
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Selected meal photo from gallery'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: appState.bgCard,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: appState.bgSubtle),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.photo_library_outlined, size: 15, color: AppTheme.textMain),
                                          const SizedBox(width: 6),
                                          Text(
                                            'From Gallery',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.textMain,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Quick Preset Snapshots (1-Tap to Attach)
                            Text(
                              'Quick presets (1-tap to attach):',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildQuickPhotoChip('Fried Rice', 'https://images.unsplash.com/photo-1596560548464-f010549b84d7?w=600&q=80', setModalState, (url) => photoUrl = url, appState),
                                  _buildQuickPhotoChip('Tofu Stew', 'https://images.unsplash.com/photo-1583032015879-6617a26f32e9?w=600&q=80', setModalState, (url) => photoUrl = url, appState),
                                  _buildQuickPhotoChip('Bibimbap', 'https://images.unsplash.com/photo-1553163147-622ab57be1c7?w=600&q=80', setModalState, (url) => photoUrl = url, appState),
                                  _buildQuickPhotoChip('Bulgogi', 'https://images.unsplash.com/photo-1632778149955-e80f8ceca2e8?w=600&q=80', setModalState, (url) => photoUrl = url, appState),
                                  _buildQuickPhotoChip('Mandu', 'https://images.unsplash.com/photo-1496116218417-1a781b1c416c?w=600&q=80', setModalState, (url) => photoUrl = url, appState),
                                  _buildQuickPhotoChip('Noodles', 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?w=600&q=80', setModalState, (url) => photoUrl = url, appState),
                                  _buildQuickPhotoChip('Pancake', 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=600&q=80', setModalState, (url) => photoUrl = url, appState),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final record = CookingRecord(
                            id: 'record_${DateTime.now().millisecondsSinceEpoch}',
                            recipeTitle: title,
                            date: _selectedDate,
                            rating: rating,
                            notes: notesController.text.trim(),
                            photoUrl: photoUrl,
                          );

                          appState.addCookingRecord(record);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Saved "$title" to your Cooking Journal!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Save to Journal',
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  void _showAddReminderDialog(BuildContext context) {
    final appState = context.read<AppState>();
    final accentColor = appState.accentColor;
    final titleController = TextEditingController();
    String reminderType = 'defrost';
    DateTime reminderDate = _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: appState.bgPrimary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'New Cooking Reminder',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMain,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Quick Preset Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ActionChip(
                            label: const Text('Unfreeze meat'),
                            onPressed: () {
                              setModalState(() {
                                titleController.text = 'Unfreeze meat in fridge for dinner';
                                reminderType = 'defrost';
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            label: const Text('Buy fresh tofu'),
                            onPressed: () {
                              setModalState(() {
                                titleController.text = 'Buy fresh tofu & scallions';
                                reminderType = 'ingredient';
                              });
                            },
                          ),
                          const SizedBox(width: 6),
                          ActionChip(
                            label: const Text('Marinate meat'),
                            onPressed: () {
                              setModalState(() {
                                titleController.text = 'Marinate pork belly 2 hrs before';
                                reminderType = 'prep';
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title Input
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Reminder Task',
                        hintText: 'e.g. Unfreeze beef brisket, Buy gochujang',
                        filled: true,
                        fillColor: AppTheme.bgSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: appState.bgSubtle),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Reminder Category Choice
                    Text(
                      'Category:',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Defrost'),
                          selected: reminderType == 'defrost',
                          onSelected: (_) => setModalState(() => reminderType = 'defrost'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Ingredients'),
                          selected: reminderType == 'ingredient',
                          onSelected: (_) => setModalState(() => reminderType = 'ingredient'),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Prep'),
                          selected: reminderType == 'prep',
                          onSelected: (_) => setModalState(() => reminderType = 'prep'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = titleController.text.trim();
                          if (title.isEmpty) return;

                          final reminder = CookingReminder(
                            id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
                            title: title,
                            scheduledDate: reminderDate,
                            reminderType: reminderType,
                          );

                          appState.addCookingReminder(reminder);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Created reminder: "$title"'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Save Reminder',
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final isTablet = MediaQuery.sizeOf(context).width >= 768;

    // Filter records for selected date
    final dayRecords = appState.cookingRecords.where((r) => _isSameDay(r.date, _selectedDate)).toList();

    // Filter reminders
    var reminders = appState.cookingReminders;
    if (_selectedReminderFilter != 'All') {
      reminders = reminders.where((r) => r.reminderType == _selectedReminderFilter.toLowerCase()).toList();
    }

    return Scaffold(
      backgroundColor: appState.bgPrimary,
      appBar: AppBar(
        backgroundColor: appState.bgPrimary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '식',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'JOURNAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textMain,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              'Meal records · Cooking reminders',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Add reminder',
            onPressed: () => _showAddReminderDialog(context),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: appState.bgCard,
                shape: BoxShape.circle,
                border: Border.all(color: appState.bgSubtle, width: 0.8),
              ),
              child: Icon(Icons.add_task_rounded, size: 16, color: accentColor),
            ),
          ),
          IconButton(
            tooltip: 'Record meal',
            onPressed: () => _showAddRecordDialog(context),
            icon: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_outlined, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isTablet
          ? _buildTabletLayout(context, appState, dayRecords, reminders)
          : _buildMobileLayout(context, appState, dayRecords, reminders),
    );
  }

  // ── Tablet / Landscape Responsive Layout ──────────────────────────────────
  Widget _buildTabletLayout(
    BuildContext context,
    AppState appState,
    List<CookingRecord> dayRecords,
    List<CookingReminder> reminders,
  ) {
    final accentColor = appState.accentColor;
    final totalThisMonth = appState.cookingRecords.where((r) => r.date.month == _selectedDate.month && r.date.year == _selectedDate.year).length;
    final activeRemindersCount = appState.cookingReminders.where((r) => !r.isCompleted).length;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Calendar & Control Station (350px width)
        Container(
          width: 350,
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(color: appState.bgSubtle),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month / Year Navigator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatMonthYear(_selectedDate),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMain,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            setState(() {
                              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Horizontal 14-day date strip
                SizedBox(
                  height: 72,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    itemBuilder: (context, index) {
                      final date = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
                      return _buildDatePill(date, appState, accentColor);
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Journal Summary / Stats Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: appState.bgSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.auto_stories_rounded, size: 18, color: accentColor),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Journal Overview',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textMain,
                                ),
                              ),
                              Text(
                                '${_selectedDate.day} ${_formatMonthYear(_selectedDate)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: appState.bgCard,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$totalThisMonth',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'This Month',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: appState.bgCard,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$activeRemindersCount',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0EA5E9),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pending',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Quick Action Buttons
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddRecordDialog(context),
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Record Cooked Meal'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showAddReminderDialog(context),
                          icon: const Icon(Icons.add_task_rounded, size: 16),
                          label: const Text('New Reminder'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textMain,
                            side: BorderSide(color: appState.bgSubtle),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Pane: Tabs & Content
        Expanded(
          child: Column(
            children: [
              // Tab Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(3.5),
                  decoration: BoxDecoration(
                    color: appState.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: appState.bgSubtle, width: 0.8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1.5)),
                      ],
                    ),
                    labelColor: AppTheme.textMain,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Cooked Journal'),
                      Tab(text: 'Cooking Reminders'),
                    ],
                  ),
                ),
              ),

              // Tab Content View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildJournalTab(context, dayRecords, appState),
                    _buildRemindersTab(context, reminders, appState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile Linear Layout ──────────────────────────────────────────────────
  Widget _buildMobileLayout(
    BuildContext context,
    AppState appState,
    List<CookingRecord> dayRecords,
    List<CookingReminder> reminders,
  ) {
    final accentColor = appState.accentColor;

    return Column(
      children: [
        // 1. Month / Year Navigator Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMonthYear(_selectedDate),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, _selectedDate.day);
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, _selectedDate.day);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Horizontal Calendar Date Strip
        SizedBox(
          height: 68,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 14,
            itemBuilder: (context, index) {
              final date = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
              return _buildDatePill(date, appState, accentColor);
            },
          ),
        ),

        const SizedBox(height: 10),

        // 3. Tab Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 42,
            padding: const EdgeInsets.all(3.5),
            decoration: BoxDecoration(
              color: appState.bgCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: appState.bgSubtle, width: 0.8),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1.5)),
                ],
              ),
              labelColor: AppTheme.textMain,
              unselectedLabelColor: AppTheme.textMuted,
              labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Cooked Journal'),
                Tab(text: 'Cooking Reminders'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 4. TabBarView Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildJournalTab(context, dayRecords, appState),
              _buildRemindersTab(context, reminders, appState),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatePill(DateTime date, AppState appState, Color accentColor) {
    final isSelected = _isSameDay(date, _selectedDate);
    final hasRecords = appState.cookingRecords.any((r) => _isSameDay(r.date, date));
    final hasReminders = appState.cookingReminders.any((r) => _isSameDay(r.scheduledDate, date));

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDate = date);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 50,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : appState.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : appState.bgSubtle,
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatDayName(date.weekday).toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isSelected ? Colors.white70 : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : AppTheme.textMain,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasRecords)
                  Container(
                    width: 3.5,
                    height: 3.5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppTheme.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (hasReminders)
                  Container(
                    width: 3.5,
                    height: 3.5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : const Color(0xFF0EA5E9),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Cooked Food Journal Tab ────────────────────────────────────────────────
  Widget _buildJournalTab(BuildContext context, List<CookingRecord> dayRecords, AppState appState) {
    final accentColor = appState.accentColor;

    if (dayRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_rounded, size: 48, color: AppTheme.textLight.withValues(alpha: 0.7)),
              const SizedBox(height: 12),
              Text(
                'No meals recorded for this day',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Take a photo of your cooked creation or log what you made.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _showAddRecordDialog(context),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Record Cooked Meal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDualColumn = constraints.maxWidth >= 540;

        if (isDualColumn) {
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.96,
            ),
            itemCount: dayRecords.length,
            itemBuilder: (context, index) {
              return _buildRecordCard(dayRecords[index], appState);
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 150),
          itemCount: dayRecords.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildRecordCard(dayRecords[index], appState),
            );
          },
        );
      },
    );
  }

  Widget _buildRecordCard(CookingRecord record, AppState appState) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: appState.bgSubtle),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (record.hasPhoto)
            Image.network(
              record.photoUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.recipeTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.textLight),
                      onPressed: () => appState.deleteCookingRecord(record.id),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Star Rating
                Row(
                  children: List.generate(5, (s) {
                    return Icon(
                      s < record.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 15,
                      color: Colors.amber,
                    );
                  }),
                ),
                if (record.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    record.notes,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Cooking Reminders Tab ──────────────────────────────────────────────────
  Widget _buildRemindersTab(BuildContext context, List<CookingReminder> reminders, AppState appState) {
    final accentColor = appState.accentColor;

    return Column(
      children: [
        // Category Filter Chips
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _reminderFilterChip('All'),
                const SizedBox(width: 6),
                _reminderFilterChip('Defrost'),
                const SizedBox(width: 6),
                _reminderFilterChip('Ingredient'),
                const SizedBox(width: 6),
                _reminderFilterChip('Prep'),
              ],
            ),
          ),
        ),

        // Reminders List
        Expanded(
          child: reminders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.event_available_rounded, size: 48, color: AppTheme.textLight),
                      const SizedBox(height: 12),
                      Text(
                        'No upcoming reminders',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Add a reminder to unfreeze meat or buy missing items.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddReminderDialog(context),
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: const Text('Add Cooking Reminder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 150),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final rem = reminders[index];
                    IconData badgeIconData = Icons.alarm_rounded;

                    if (rem.reminderType == 'defrost') {
                      badgeIconData = Icons.ac_unit_rounded;
                    } else if (rem.reminderType == 'ingredient') {
                      badgeIconData = Icons.shopping_basket_outlined;
                    } else if (rem.reminderType == 'prep') {
                      badgeIconData = Icons.restaurant_rounded;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: appState.bgSubtle),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: rem.isCompleted,
                            activeColor: AppTheme.textMain,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (_) => appState.toggleCookingReminder(rem.id),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: appState.bgSubtle,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              badgeIconData,
                              size: 13,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rem.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: rem.isCompleted ? AppTheme.textLight : AppTheme.textMain,
                                    decoration: rem.isCompleted ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${rem.scheduledDate.month}/${rem.scheduledDate.day} · ${rem.reminderType.toUpperCase()}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: AppTheme.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textLight),
                            onPressed: () => appState.deleteCookingReminder(rem.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _reminderFilterChip(String label) {
    final appState = context.watch<AppState>();
    final accentColor = appState.accentColor;
    final isSelected = _selectedReminderFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: accentColor,
      backgroundColor: appState.bgCard,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.textMain,
      ),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? accentColor : appState.bgSubtle,
        width: 1,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (_) {
        setState(() => _selectedReminderFilter = label);
      },
    );
  }

  Widget _buildQuickPhotoChip(
    String label,
    String url,
    StateSetter setModalState,
    void Function(String) onSelect,
    AppState appState,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setModalState(() {
            onSelect(url);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: appState.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: appState.bgSubtle),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMain,
            ),
          ),
        ),
      ),
    );
  }
}
