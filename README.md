# Path Extrapolation

An interactive Flutter application demonstrating path extrapolation with geometric constraints, circle packing, and precise endpoint clipping.

## Demo

### Screenshot

### Video Demo

📹 **[Download Demo Video](demo/video.mp4)** (Click to download and watch)

## Features

- **Interactive Canvas**: Drag points to manipulate the path in real-time
- **Point Reduction**: Deterministic selection of reduced point from candidate points using projection
- **Smooth Path Generation**: Catmull-Rom spline interpolation through 5 points
- **Circle Packing**: Edge-to-edge circle placement along the path with no gaps
- **Exact End Clipping**: Precise clipping of the final circle at path endpoint
- **Debug Overlays**: Visualization of projection/reduction process
- **Animation**: Optional animated circle progression along the path

## Architecture

The project follows clean architecture principles with:

- **Cubit** for state management (flutter_bloc)
- **Freezed** for immutable state models
- **Injectable + GetIt** for dependency injection
- **Separation of concerns** with distinct layers

### Folder Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart          # App-wide constants
│   └── di/
│       ├── injection.dart               # DI configuration
│       └── injection.config.dart        # Generated DI code
├── domain/
│   ├── models/
│   │   ├── path_state_model.dart       # State model
│   │   └── point_model.dart            # Point model
│   └── services/
│       └── geometry_service.dart       # Geometry calculations
├── presentation/
│   ├── cubit/
│   │   └── path_cubit.dart             # State management
│   ├── pages/
│   │   └── home_page.dart              # Main page
│   └── widgets/
│       ├── control_panel.dart          # UI controls
│       ├── path_canvas.dart            # Interactive canvas
│       └── path_painter.dart           # Custom painter
└── main.dart                            # App entry point
```

## Setup

### Prerequisites

- Flutter SDK (3.10.7 or higher)
- Dart SDK

### Installation

1. Clone the repository
2. Install dependencies:

```bash
flutter pub get
```

3. Generate code (Freezed, Injectable):

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:

```bash
flutter run
```

## Design Decisions

### 1. Reduction Step

The reduction algorithm:

- Takes 3 candidate points (amber colored)
- Computes best-fit line using least squares (PCA approach)
- Projects each candidate onto this line
- Selects the projected point at maximum distance from the first regular point (P2)
- This ensures deterministic selection for identical inputs

### 2. Path Generation

- Uses Catmull-Rom spline for smooth interpolation
- Ensures C1 continuity (smooth first derivative)
- Handles edge cases: straight lines, single points, two points
- 100 segments per path section for smoothness

### 3. Circle Packing

- Circles placed edge-to-edge (diameter spacing)
- First circle boundary starts exactly at path start
- Uses path metrics for precise distance calculations
- Works with arbitrary path curvature

### 4. End Clipping

- Detects when final circle extends beyond path end
- Creates clip path perpendicular to path direction at endpoint
- Uses canvas clipping for precise boundary
- No visual artifacts or flickering

### 5. State Management

- Cubit provides clean separation of business logic
- Freezed ensures immutable state
- All geometry calculations in separate service
- Painter is pure (no side effects)

## Edge Cases Handled

### Straight Path

- Degenerates to linear interpolation
- Circle packing works correctly
- Clipping still precise

### Vertical/Horizontal Paths

- Best-fit line handles all orientations
- No division by zero issues
- Projection works in all directions

### Bent/Curved Paths

- Catmull-Rom handles arbitrary curvature
- Circle placement follows path naturally
- Clipping adapts to path direction

### Single/Two Points

- Graceful degradation
- No crashes or visual glitches
- Appropriate fallback rendering

### Degenerate Configurations

- Collinear candidate points
- Overlapping points
- Zero-length path segments

## Controls

- **Projection Overlay**: Show/hide reduction step visualization
- **Circle Packing**: Toggle circle rendering
- **Clipping Boundary**: Show/hide endpoint markers
- **Animate Circles**: Progressive circle appearance animation

## Point Types

- **Amber**: Candidate points (used in reduction)
- **Purple**: Reduced point (selected from projections)
- **Green**: Regular points (complete the 5-point path)

## Technical Highlights

- **Deterministic**: Same input always produces same output
- **Performant**: Efficient path metrics and calculations
- **Maintainable**: Clean architecture with clear separation
- **Testable**: Services and logic isolated from UI
- **Extensible**: Easy to add new features or modify behavior

## Dependencies

```yaml
dependencies:
  flutter_bloc: ^8.1.3
  freezed_annotation: ^2.4.1
  injectable: ^2.3.2
  get_it: ^7.6.4

dev_dependencies:
  build_runner: ^2.4.6
  freezed: ^2.4.5
  injectable_generator: ^2.4.1
```
