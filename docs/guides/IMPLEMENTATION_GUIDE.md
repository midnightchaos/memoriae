# Implementation Guide - Memoriae Flutter App

## Overview
This document provides a detailed guide on the Flutter implementation of the Memoriae app based on the Figma design.

## Architecture

### State Management
Currently using **StatefulWidget** for local state management. For future scaling, consider:
- **Provider** - Simple and effective
- **Riverpod** - More robust, recommended for larger apps
- **Bloc** - For complex state management needs

### Navigation
- **Bottom Navigation Bar** - Main app navigation
- **Navigator.push/pop** - Screen transitions
- **PageRouteBuilder** - Custom transitions with animations

## Screen-by-Screen Breakdown

### 1. Splash Screen (`splash_screen.dart`)
**Purpose**: Initial loading screen with brand identity

**Animations**:
- Fade-in: 0-600ms
- Scale: 0-600ms
- Auto-navigate: 3000ms

**Key Components**:
- `AnimationController` with `SingleTickerProviderStateMixin`
- `CurvedAnimation` for smooth easing
- Gradient background matching brand colors
- Large emoji icon (💜) with breathing effect

**Transition**:
```dart
PageRouteBuilder(
  transitionDuration: Duration(milliseconds: 800),
  pageBuilder: (context, animation, secondaryAnimation) => MainNavigationScreen(),
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return FadeTransition(opacity: animation, child: child);
  },
)
```

### 2. Main Navigation (`main_navigation_screen.dart`)
**Purpose**: Container for bottom navigation and screen switching

**Navigation Structure**:
```
Home (🏠) → HomeScreen
Draw (🎨) → DrawingTherapyScreen
Faces (👥) → FacesScreen
Relax (🧘) → RelaxScreen
You (👤) → ProfileScreen
```

**Key Features**:
- Custom bottom navigation with gradient selection
- AnimatedSwitcher for screen transitions
- Floating action button (chat bot)
- Responsive to theme changes

**Bottom Nav Animation**:
- Selected item: Gradient background + scale up
- Unselected: Transparent + normal size
- Transition: 300ms

### 3. Home Screen (`home_screen.dart`)
**Purpose**: Main dashboard with personalized greeting and feature access

**Dynamic Content**:
```dart
// Greeting based on time
hour < 12 ? 'Good Morning' 
  : hour < 17 ? 'Good Afternoon' 
  : 'Good Evening'

// Date formatting
DateFormat('EEEE, MMMM d').format(DateTime.now())
```

**Layout**:
```
Header (Menu button + spacing)
  ↓
Greeting Card (gradient container)
  ├─ Emoji (animated scale)
  ├─ Greeting + Name
  ├─ Current Date
  └─ Weather
  ↓
Feature Grid (2 columns × 3 rows)
  ├─ Memory Journal
  ├─ Familiar Faces
  ├─ Daily Routine
  ├─ Location Safety
  ├─ Memory Games
  └─ My Meds
  ↓
Settings Button
```

**Feature Card Structure**:
- Background gradient (unique per feature)
- Dot pattern overlay (CustomPainter)
- Large emoji icon (64px)
- Two-line label
- Arrow indicator
- Shadow and hover effects

### 4. Drawing Therapy (`drawing_therapy_screen.dart`)
**Purpose**: Therapeutic drawing canvas

**Technical Implementation**:
```dart
// Drawing state
List<Offset?> _points = [];  // null separates strokes
Color _selectedColor = Colors.purple;

// Touch handling
GestureDetector(
  onPanUpdate: (details) {
    setState(() => _points.add(details.localPosition));
  },
  onPanEnd: (details) {
    setState(() => _points.add(null));  // Stroke separator
  },
)

// Custom painter
class DrawingPainter extends CustomPainter {
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }
}
```

**Color Palette**:
- 6 predefined colors
- Animated selection (size + glow)
- Circular buttons with shadow

**Actions**:
- Clear canvas (reset points list)
- Save drawing (to be implemented)
- Share drawing (to be implemented)

### 5. Familiar Faces (`faces_screen.dart`)
**Purpose**: Manage and view family/caregiver contacts

**Data Structure**:
```dart
List<Map<String, String>> familiarFaces = [
  {'name': 'Sarah', 'relation': 'Daughter', 'emoji': '👩'},
  {'name': 'Michael', 'relation': 'Son', 'emoji': '👨'},
  // ...
];
```

**Features**:
- Add new face (dialog)
- View face details (dialog)
- Contact actions (call/message)

**List Item Design**:
```
[Emoji Container] [Name + Relation] [Arrow]
     64×64           Flexible         20px
```

### 6. Relax Screen (`relax_screen.dart`)
**Purpose**: Access to therapeutic activities

**Layout**:
```
Featured Activity Card
  ├─ Large emoji
  ├─ Title + duration
  └─ Start button
  ↓
Therapy Options Grid (2×2)
  ├─ Music Therapy
  ├─ Art Therapy
  ├─ Meditation
  └─ Breathing Exercises
```

**Card Colors**:
- Each option has unique color scheme
- Border matches main color
- Shadow matches main color

### 7. Profile Screen (`profile_screen.dart`)
**Purpose**: User profile and app settings

**Profile Card**:
- Avatar (gradient container + emoji)
- Name, age, member since
- Gradient background

**Settings Menu Items**:
```dart
[
  {'icon': '👤', 'title': 'Personal Information', ...},
  {'icon': '🔔', 'title': 'Notifications', ...},
  {'icon': '🌓', 'title': 'Dark Mode', ...},
  {'icon': '👨‍👩‍👧', 'title': 'Caregiver Access', ...},
  {'icon': '🔒', 'title': 'Privacy & Security', ...},
  {'icon': 'ℹ️', 'title': 'About Memoriae', ...},
]
```

## Theme System (`app_theme.dart`)

### Color System
```dart
// Primary colors
lavender50-900  // Calming, primary brand
blue50-500      // Trust, stability
emerald50-500   // Wellness, growth
teal400-800     // Accent

// Supporting
peach50-400     // Warmth
rose400         // Affection
mint50-400      // Freshness
coral400        // Attention
cyan400         // Clarity

// Neutrals
slate50-900     // Text and backgrounds
cream50         // Warm neutral
```

### Gradient System
```dart
// Calm gradient (background)
[lavender50, blue50, emerald50]

// Lavender gradient (cards)
[lavender100, peach100]

// Teal gradient (accents)
[teal500, emerald500, cyan400]
```

### Typography
```dart
displayLarge:  48px, weight 300  // Hero text
displayMedium: 36px, weight 300  // Section headers
titleLarge:    24px, weight 500  // Card titles
titleMedium:   20px, weight 500  // Subtitles
bodyLarge:     18px, weight 400  // Body text
bodyMedium:    16px, weight 400  // Secondary text
labelLarge:    16px, weight 500  // Button labels
```

### Component Styles
```dart
// Cards
elevation: 4
borderRadius: 24px
color: white (light) / slate800 (dark)

// Buttons
padding: 32×16
borderRadius: 24px
elevation: 2

// FAB
backgroundColor: lavender500/400
borderRadius: 20px
elevation: 8
```

## Animation Guidelines

### Timing
- **Fast**: 150-200ms - Button presses
- **Normal**: 300-400ms - Screen transitions
- **Slow**: 600-800ms - Fade-in effects
- **Very Slow**: 2-4s - Breathing animations

### Curves
- `Curves.easeOut` - Exit animations
- `Curves.easeIn` - Enter animations
- `Curves.easeInOut` - Screen transitions
- `Curves.linear` - Progress indicators

### Common Patterns
```dart
// Fade + Slide
Transform.translate(
  offset: Offset(0, 20 * (1 - animation.value)),
  child: Opacity(
    opacity: animation.value,
    child: child,
  ),
)

// Scale pulse
TweenAnimationBuilder(
  tween: Tween<double>(begin: 0.8, end: 1.0),
  duration: Duration(seconds: 2),
  curve: Curves.easeInOut,
  builder: (context, value, child) {
    return Transform.scale(scale: value, child: child);
  },
)
```

## Best Practices

### Performance
1. **Use `const` constructors** wherever possible
2. **Extract widgets** for repeated components
3. **Dispose controllers** in dispose() method
4. **Avoid rebuilding** entire trees unnecessarily

### Accessibility
1. **Semantic labels** on all interactive elements
2. **Touch targets** minimum 48×48 dp
3. **Text contrast** 4.5:1 minimum
4. **Font scaling** support system text size

### Code Organization
```dart
// Order: statics, fields, constructors, lifecycle, builders
class MyWidget extends StatefulWidget {
  static const duration = Duration(milliseconds: 300);
  
  final String title;
  final VoidCallback? onTap;
  
  const MyWidget({super.key, required this.title, this.onTap});
  
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, ...);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(...);
  }
  
  void _handleTap() {
    // Event handlers
  }
}
```

## Testing Strategy

### Unit Tests
- Theme color values
- Animation durations
- Date/time formatting
- State management logic

### Widget Tests
- Screen rendering
- Navigation flow
- Button interactions
- Dialog display

### Integration Tests
- Full user flows
- Screen transitions
- Data persistence
- Error handling

## Deployment Checklist

### Before Release
- [ ] Test on multiple devices/sizes
- [ ] Verify all animations
- [ ] Check dark mode compatibility
- [ ] Test accessibility features
- [ ] Optimize images/assets
- [ ] Update app version
- [ ] Add release notes
- [ ] Test on older OS versions

### Performance Targets
- App launch: < 2 seconds
- Screen transition: < 400ms
- Drawing latency: < 16ms (60fps)
- Memory usage: < 200MB

## Future Implementation

### Priority 1 (High)
1. Data persistence (SQLite/Hive)
2. Notification system
3. Photo upload for faces
4. Basic chatbot responses

### Priority 2 (Medium)
1. Medication tracking
2. Location services
3. Memory games
4. Daily routine manager

### Priority 3 (Nice to have)
1. Voice commands
2. Video calling
3. Advanced AI chatbot
4. Analytics dashboard

## Dependencies Reference

```yaml
# Current
cupertino_icons: ^1.0.8
intl: ^0.19.0

# Recommended for future
# State management
provider: ^6.0.0
riverpod: ^2.0.0

# Storage
sqflite: ^2.0.0
hive: ^2.0.0
shared_preferences: ^2.0.0

# Network
http: ^1.0.0
dio: ^5.0.0

# Image
image_picker: ^1.0.0
cached_network_image: ^3.0.0

# Location
geolocator: ^9.0.0
google_maps_flutter: ^2.0.0

# Notifications
flutter_local_notifications: ^15.0.0

# Audio/Video
just_audio: ^0.9.0
video_player: ^2.0.0

# AI/ML
google_ml_kit: ^0.16.0
```

---

**Note**: This is a living document. Update as the app evolves.
