# App Icon Requirements

Place PNG files in this directory with the following names and sizes:

## iPhone Icons
| Filename | Size | Scale | Usage |
|----------|------|-------|-------|
| AppIcon-20x20@2x.png | 40x40 | 2x | Notification |
| AppIcon-20x20@3x.png | 60x60 | 3x | Notification |
| AppIcon-29x29@2x.png | 58x58 | 2x | Settings |
| AppIcon-29x29@3x.png | 87x87 | 3x | Settings |
| AppIcon-40x40@2x.png | 80x80 | 2x | Spotlight |
| AppIcon-40x40@3x.png | 120x120 | 3x | Spotlight |
| AppIcon-60x60@2x.png | 120x120 | 2x | Home Screen |
| AppIcon-60x60@3x.png | 180x180 | 3x | Home Screen |

## iPad Icons
| Filename | Size | Scale | Usage |
|----------|------|-------|-------|
| AppIcon-20x20@1x.png | 20x20 | 1x | Notification |
| AppIcon-20x20@2x.png | 40x40 | 2x | Notification |
| AppIcon-29x29@1x.png | 29x29 | 1x | Settings |
| AppIcon-29x29@2x.png | 58x58 | 2x | Settings |
| AppIcon-40x40@1x.png | 40x40 | 1x | Spotlight |
| AppIcon-40x40@2x.png | 80x80 | 2x | Spotlight |
| AppIcon-76x76@1x.png | 76x76 | 1x | Home Screen |
| AppIcon-76x76@2x.png | 152x152 | 2x | Home Screen |
| AppIcon-83.5x83.5@2x.png | 167x167 | 2x | Home Screen (iPad Pro) |

## App Store
| Filename | Size | Scale | Usage |
|----------|------|-------|-------|
| AppIcon-1024x1024@1x.png | 1024x1024 | 1x | App Store |

## Design Guidelines
- Format: PNG with transparency (24-bit color + 8-bit alpha)
- Corner radius: iOS automatically applies mask, but design with square corners
- Content: Keep main content within the center safe area (approx 80% of icon)
- Background: Can be transparent or solid color
- Style: Simple, recognizable design that works at small sizes

## Quick Generation
You can use online tools like:
- [App Icon Generator](https://appicon.co/)
- [MakeAppIcon](https://makeappicon.com/)

Or use ImageMagick:
```bash
# Generate all sizes from a 1024x1024 source
convert source.png -resize 40x40 AppIcon-20x20@2x.png
convert source.png -resize 60x60 AppIcon-20x20@3x.png
# ... etc for all sizes
```
