# Face Matching Minigame - Visual Reference Guide

## Screen Layout

```
┌─────────────────────────────────────┐
│  ← Back    Face Matching    🔄      │  ← Header with nav
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │   Score  │ Matched │ Attempts│   │  ← Score Bar (gradient purple/lavender)
│  │     30   │   3/6   │    5    │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ ℹ️ Tap a face, then tap the   │ │  ← Instructions
│  │   matching name!              │ │
│  └───────────────────────────────┘ │
│                                     │
│         Faces                       │  ← Section Header
│                                     │
│  ┌─────┐  ┌─────┐  ┌─────┐        │
│  │     │  │  ✓  │  │     │        │  ← Face Grid (3 columns)
│  │ 👤  │  │ 👤  │  │ 👤  │        │    (checked = matched)
│  │  •  │  │  •  │  │  •  │        │    (dot = color indicator)
│  └─────┘  └─────┘  └─────┘        │
│                                     │
│  ┌─────┐  ┌─────┐  ┌─────┐        │
│  │     │  │     │  │     │        │
│  │ 👤  │  │ 👤  │  │ 👤  │        │
│  │  •  │  │  •  │  │  •  │        │
│  └─────┘  └─────┘  └─────┘        │
│                                     │
│         Names                       │  ← Section Header
│                                     │
│  ┌────────┐ ┌────────┐ ┌────────┐ │
│  │ Alice  │ │ Bob ✓  │ │ Carol  │ │  ← Name Chips (wrapped)
│  └────────┘ └────────┘ └────────┘ │
│  ┌────────┐ ┌────────┐ ┌────────┐ │
│  │ David  │ │ Emma   │ │ Frank  │ │
│  └────────┘ └────────┘ └────────┘ │
│                                     │
└─────────────────────────────────────┘
```

## Color Scheme

### Face Card Colors (8 rotating colors)
```
Face 1: Lavender (#A78BFA) - Light purple
Face 2: Rose (#FB7185) - Pink/rose
Face 3: Blue (#60A5FA) - Sky blue
Face 4: Emerald (#34D399) - Green
Face 5: Peach (#FDBA74) - Orange/peach
Face 6: Teal (#2DD4BF) - Cyan/teal
Face 7: Purple (#C084FC) - Deep purple
Face 8: Mint (#6EE7B7) - Light green
```

### State Colors
```
Selected: Bright color border (3px) + shadow
Matched: Emerald green (#34D399) checkmark + faded
Normal: Subtle color border (2px) + light shadow
Wrong: Brief highlight then fade
```

## Game States

### 1. Loading State
```
┌─────────────────────────────────────┐
│           Face Matching             │
├─────────────────────────────────────┤
│                                     │
│                                     │
│              ⟳                      │  ← Spinner
│         Loading...                  │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

### 2. Insufficient Faces
```
┌─────────────────────────────────────┐
│           Face Matching             │
├─────────────────────────────────────┤
│                                     │
│              😔                      │
│                                     │
│       Not enough faces              │  ← Message
│  Add at least 3 familiar faces      │
│        to play                      │
│                                     │
│       ┌────────────┐                │
│       │  Go Back   │                │  ← Button
│       └────────────┘                │
│                                     │
└─────────────────────────────────────┘
```

### 3. Completion Dialog
```
        ┌───────────────────────┐
        │ 🎉 Congratulations! 🎉│
        ├───────────────────────┤
        │                       │
        │ You matched all the   │
        │ faces!                │
        │                       │
        │ Score:      30 points │
        │ Attempts:   5         │
        │ Accuracy:   60%       │
        │                       │
        ├───────────────────────┤
        │  Exit  │  Play Again  │
        └───────────────────────┘
```

## Interaction Flow

### Selection States

#### No Selection
```
Face:  [Normal border]
Name:  [Normal border]
```

#### Face Selected
```
Face:  [BRIGHT color border + scale up]
Name:  [Normal border]
Action: Waiting for name tap
```

#### Name Selected (no face)
```
Face:  [Normal border]
Name:  [BRIGHT color border + scale up]
Action: Name deselects on tap
```

#### Both Selected - MATCH! ✓
```
Face:  [Green checkmark overlay + fade]
Name:  [Green checkmark + fade]
Score: +10 points
Action: Clear selections
```

#### Both Selected - WRONG ✗
```
Face:  [Brief highlight]
Name:  [Brief highlight]
Wait:  500ms
Action: Clear selections
```

## Animation Timing

```
Selection Scale:     200ms (AnimatedScale)
Match Celebration:   500ms (elastic bounce)
Wrong Match Delay:   500ms (before clear)
Checkmark Appear:    300ms (fade in)
Button Press:        150ms (ripple effect)
```

## Responsive Layout

### Mobile Portrait (default)
- 3 columns for faces
- Names wrap naturally
- Cards: 0.8 aspect ratio

### Tablet/Large Screen
- Could expand to 4 columns
- Larger cards
- More spacing

## Accessibility Notes

### Visual Feedback
- Color coding helps matching
- Large tap targets (120px+ faces)
- Clear selection states
- High contrast borders

### Cognitive Accessibility  
- Simple one-action-at-a-time
- Clear instructions
- Immediate feedback
- No time pressure
- Can restart anytime

## Theme Support

### Light Mode
```
Background: Gradient (lavender → blue → mint)
Cards: White with subtle shadows
Text: Dark slate
Borders: Colored with opacity
```

### Dark Mode
```
Background: Gradient (slate900 → slate800)
Cards: Slate800 with shadows
Text: White
Borders: Colored with opacity
```

## Score Bar Design

```
┌─────────────────────────────────────┐
│       Score     │  Matched  │ Attempts │  ← Labels
│         30      │    3/6    │    5     │  ← Values (large, bold)
│                 │           │          │
└─────────────────────────────────────┘
  Gradient: Purple → Lavender
  Shadow: Soft purple glow
  Dividers: White 30% opacity
```

## Card Anatomy

### Face Card
```
┌─────────────┐
│             │ ← Photo or gradient
│     👤      │   with person icon
│             │
├─────────────┤
│      •      │ ← Color dot indicator
└─────────────┘
  Border: 2-3px colored
  Corners: 16px radius
  Shadow: 8-16px blur
```

### Name Chip
```
┌──────────────┐
│  Alice   ✓   │ ← Name + optional checkmark
└──────────────┘
  Padding: 20px × 12px
  Corners: 20px radius (pill)
  Border: 1.5-2px colored
  Shadow: 6-12px blur
```

## Color Association Example

```
Face #1 (Alice):   Border: Lavender
                   Dot: Lavender
                   
When selected:     Border: Bright lavender
                   Shadow: Lavender glow
                   
Name chip (Alice): Border: Lavender (matches!)
                   Background: White/Slate

When matched:      Both show ✓ green
                   Opacity: 40%
```

## Success Indicators

### Visual Cues
- ✓ Green checkmark on matched items
- Fade to 40% opacity when matched
- Green emerald border on completion
- Score increments (+10)
- Matched counter updates (3/6 → 4/6)

### Celebration
- Dialog pops up when all matched
- Confetti emoji (🎉)
- Statistics display
- Positive messaging
- Options to replay or exit

This visual guide should help understand the complete UI/UX design!
