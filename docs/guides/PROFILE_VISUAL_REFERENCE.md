# My Profile Screen - Quick Visual Reference

## 🎨 Screen Layout Overview

```
┌─────────────────────────────────────┐
│  ← Back    MY PROFILE       🔄      │  ← Header
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐ │
│  │  👤                           │ │
│  │  John Doe                    │ │  ← User Identity Card
│  │  Patient                      │ │  (Gradient: Lavender→Teal)
│  │  ─────────────────────────── │ │
│  │  Age: 75 | Account: 45 days  │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌──────────┐  ┌──────────┐       │
│  │ 💬       │  │ 🔥       │       │
│  │  127     │  │ 5 days   │       │  ← Quick Stats (2x2 Grid)
│  │ Chats    │  │ Streak   │       │
│  └──────────┘  └──────────┘       │
│  ┌──────────┐  ┌──────────┐       │
│  │ 📝       │  │ 🎮       │       │
│  │  15      │  │  28      │       │
│  │ Journals │  │ Games    │       │
│  └──────────┘  └──────────┘       │
│                                     │
│  📈 ACTIVITY TRENDS                │
│  ┌───────────────────────────────┐ │
│  │                        /\      │ │
│  │                    /\/   \     │ │  ← 30-Day Engagement Chart
│  │              __/\/        \/   │ │
│  │      __/\__/                   │ │
│  │  ___/                          │ │
│  └───────────────────────────────┘ │
│                                     │
│  💬 CHAT ACTIVITY                  │
│  ┌───────────────────────────────┐ │
│  │ 💬 Total Conversations    127 │ │
│  │ ───────────────────────────── │ │
│  │ 📊 Avg per Day           2.8  │ │  ← Chat Analytics Card
│  │ ───────────────────────────── │ │
│  │ 📅 Avg per Week         19.6  │ │
│  │ ───────────────────────────── │ │
│  │ 🔥 Chat Streak         5 days │ │
│  └───────────────────────────────┘ │
│                                     │
│  📚 CONTENT & MEDIA                │
│  ┌───────────────────────────────┐ │
│  │ 📝 Journal Entries         15 │ │
│  │ ───────────────────────────── │ │
│  │ 🎮 Games Played            28 │ │
│  │ ───────────────────────────── │ │
│  │ Mood Distribution             │ │  ← Content Summary Card
│  │ 😊 Happy      8x              │ │
│  │ 😌 Calm       4x              │ │
│  │ 😔 Sad        3x              │ │
│  │ ───────────────────────────── │ │
│  │ Top Tags                      │ │
│  │ [family] [health] [memory]    │ │
│  └───────────────────────────────┘ │
│                                     │
│  📊 PROGRESS INSIGHTS              │
│  ┌───────────────────────────────┐ │
│  │ This Week                     │ │
│  │ 💬 Chats              19      │ │
│  │ 📝 Journals            3      │ │  ← Progress Card
│  │ 🎮 Games               7      │ │
│  │ ───────────────────────────── │ │
│  │ This Month                    │ │
│  │ 💬 Chats              87      │ │
│  │ 📝 Journals           12      │ │
│  │ 🎮 Games              21      │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │        📤                     │ │
│  │   Share with Caregiver        │ │
│  │ Share your location & stats   │ │  ← Caregiver Share Button
│  │                               │ │  (Gradient: Peach→Coral)
│  │      [ SHARE NOW ]            │ │
│  └───────────────────────────────┘ │
│                                     │
└─────────────────────────────────────┘
```

---

## 🎨 Color Palette

### User Identity Card
```
┌─────────────────┐
│ Gradient:       │
│ #A78BFA → #2DD4BF │  Lavender 400 → Teal 400
│                 │
│ Text: White     │
└─────────────────┘
```

### Quick Stats Cards
```
┌─────────────────┐
│ Background:     │
│ White / Slate800│  Light/Dark mode adaptive
│                 │
│ Icon: Emoji     │
│ Number: Bold    │
│ Label: Grey     │
└─────────────────┘
```

### Chart Colors
```
Line Color: #A78BFA    (Lavender 400)
Fill Color: #A78BFA33  (Lavender 400 @ 20% opacity)
Grid: Hidden
Background: White/Slate800
```

### Caregiver Button
```
┌─────────────────┐
│ Gradient:       │
│ #FB923C → #F87171 │  Peach 400 → Coral 400
│                 │
│ Text: White     │
│ Button: White bg│
└─────────────────┘
```

---

## 📐 Spacing & Layout

### Card Padding
```
User Identity:    20px all sides
Quick Stats:      16px all sides
Charts:           16px all sides
Metric Cards:     16px all sides
Share Button:     20px all sides
```

### Border Radius
```
Identity Card:    20px
Stats Cards:      16px
Charts:           16px
Metric Cards:     16px
Share Button:     20px
Chips (Tags):     12px
```

### Gaps Between Elements
```
Sections:         20px vertical
Cards in Grid:    12px horizontal + vertical
List Items:       8px vertical
Dividers:         24px height
```

---

## 📱 Responsive Behavior

### Quick Stats Grid
```
Mobile:   2 columns × 2 rows
Tablet:   2 columns × 2 rows (same, larger cards)
```

### Chart Height
```
Fixed: 220px (optimal for mobile visibility)
```

### Scroll Behavior
```
- Header: Fixed at top
- Content: Vertical scroll
- Button: Scrolls with content (always accessible)
```

---

## 🎭 State Variations

### Loading State
```
┌─────────────────────────────────────┐
│                                     │
│              ⏳                     │
│      CircularProgressIndicator      │
│                                     │
└─────────────────────────────────────┘
```

### Error State
```
┌─────────────────────────────────────┐
│              ⚠️                     │
│    Failed to load analytics         │
│                                     │
│         [ RETRY ]                   │
└─────────────────────────────────────┘
```

### Empty State (No Data)
```
┌───────────────────────────────────┐
│                                   │
│     No activity data yet          │
│                                   │
└───────────────────────────────────┘
```

---

## 🔄 Interaction Flows

### 1. Initial Load
```
Open Screen → Show Loading → Fetch Analytics → Display Data
```

### 2. Refresh
```
Tap Refresh Icon → Show Loading → Clear Cache → Fetch Analytics → Display Data
```

### 3. Caregiver Share
```
Tap Share Button
    ↓
Confirmation Dialog
    ↓ (Confirm)
Request Location Permission
    ↓ (Granted)
Fetch GPS Coordinates
    ↓
Compile Report
    ↓
Show Share Options (WhatsApp / Gmail / Other)
    ↓ (Select)
Open App with Pre-filled Content
```

---

## 📊 Data Visualization Details

### Line Chart (Activity Trends)
```
X-Axis: Last 30 days (M/d format)
Y-Axis: Total interactions (0-max)
Line: Smooth curve (isCurved: true)
Fill: Gradient below line
Dots: Hidden (cleaner look)
Grid: Hidden (minimal distraction)
```

### Metric Rows
```
┌─────────────────────────────────────┐
│ [Emoji]  Label          Value       │
│  💬      Total Chats       127      │
└─────────────────────────────────────┘
       12px gap      Spacer    Bold
```

### Mood Distribution
```
😊 Happy      8x    ───────────█████████
😌 Calm       4x    ─────█████
😔 Sad        3x    ────███

(Shown as text rows, not progress bars)
```

### Tag Chips
```
[family]  [health]  [memory]  [exercise]

Chip Style:
- Background: Lavender 100
- Text: 12px
- Padding: 8px horizontal, 4px vertical
- Rounded: 12px
```

---

## 🎯 Key Interactive Elements

### Refresh Button (Top Right)
```
Icon: refresh (circular arrows)
Size: 24px
Action: Invalidate cache + reload analytics
Feedback: Show loading indicator
```

### Share Button (Bottom)
```
Style: White button on gradient background
Size: Full width - 32px margin
Action: Open share confirmation dialog
States: Normal, Pressed
```

### Back Button (Top Left)
```
Icon: arrow_back
Size: 28px
Action: Navigator.pop()
```

---

## 📝 Text Styles

### Headers
```
Section Headers:
  Font: 18px, Bold
  Color: Default text color
  Icon: 24px, Lavender 400

Card Titles:
  Font: 16px, Bold
  Color: Default text color
```

### Body Text
```
Metric Labels:
  Font: 14px, Regular
  Color: Default text color

Metric Values:
  Font: 16px, Bold
  Color: Default text color

Secondary Text:
  Font: 12px, Regular
  Color: Grey 400/600 (dark/light)
```

### User Identity
```
Name: 24px, Bold, White
Type: 14px, Regular, White 90%
Info Labels: 14px, Regular, White 80%
Info Values: 14px, SemiBold, White
```

---

## 🔍 Accessibility Features

### Screen Reader Support
- All cards have semantic labels
- Chart data is described textually
- Buttons have clear action descriptions

### High Contrast Mode
- Text maintains 4.5:1 contrast ratio
- Icons use sufficient size (≥24px)
- Focus indicators are visible

### Touch Targets
- All buttons ≥48px touch area
- Cards have sufficient spacing
- No overlapping interactive elements

---

## 📦 Component Breakdown

### Reusable Widgets

#### `_buildSectionHeader(title, icon)`
```dart
Row(
  Icon(icon) + SizedBox(8) + Text(title)
)
```

#### `_buildMetricRow(label, value, emoji)`
```dart
Row(
  Row(emoji + label) + Spacer + Text(value)
)
```

#### `_buildInfoRow(label, value)`
```dart
Row(
  Text(label) + Spacer + Text(value)
)
```

#### `_buildEmptyState(message)`
```dart
Container(
  height: 150,
  child: Center(Text(message))
)
```

---

## 🎬 Animation Opportunities (Future)

### Entry Animations
```
Identity Card: Fade + Scale from 0.9 to 1.0
Stats Grid: Stagger each card by 50ms
Chart: Draw line from left to right
Cards: Fade + Slide up
```

### Interaction Animations
```
Refresh Button: Rotate 360° during load
Share Button: Pulse scale on press
Metric Cards: Ripple effect on tap (if made interactive)
```

### Transition Animations
```
Loading → Content: Fade transition
Error → Content: Cross-fade
Empty → Content: Fade + grow
```

---

## 📱 Platform-Specific Behaviors

### Android
- Material ripple effects on buttons
- Standard elevation shadows
- System back button support

### iOS
- Cupertino-style scrolling physics
- Native share sheet
- Swipe-to-go-back gesture

---

## 🧪 Test Data Examples

### Sample Analytics Output
```dart
UserAnalytics(
  name: 'John Doe',
  age: 75,
  userType: 'Patient',
  accountAge: Duration(days: 45),
  totalChats: 127,
  avgChatsPerDay: 2.8,
  avgChatsPerWeek: 19.6,
  currentStreak: 5,
  sessionCount: 42,
  totalTimeSpent: Duration(hours: 6, minutes: 14),
  journalEntries: 15,
  gamesPlayed: 28,
  moodDistribution: {
    '😊': 8,
    '😌': 4,
    '😔': 3,
  },
  topTags: ['family', 'health', 'memory'],
  weeklyTrends: {
    'chats': 19,
    'journals': 3,
    'games': 7,
  },
  monthlyTrends: {
    'chats': 87,
    'journals': 12,
    'games': 21,
  },
)
```

---

**Visual Reference Version**: 1.0  
**Last Updated**: December 22, 2025  
**Designer**: AI Assistant
