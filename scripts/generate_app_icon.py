#!/usr/bin/env python3
"""
Generate Anji App Icons
Creates a set of iOS app icons with gradient background and brain/book symbol.
Requires: pip install Pillow
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Icon specifications for iOS
ICON_SPECS = [
    # iPhone
    ("AppIcon-20x20@2x.png", 40),
    ("AppIcon-20x20@3x.png", 60),
    ("AppIcon-29x29@2x.png", 58),
    ("AppIcon-29x29@3x.png", 87),
    ("AppIcon-40x40@2x.png", 80),
    ("AppIcon-40x40@3x.png", 120),
    ("AppIcon-60x60@2x.png", 120),
    ("AppIcon-60x60@3x.png", 180),
    # iPad
    ("AppIcon-20x20@1x.png", 20),
    ("AppIcon-20x20@2x.png", 40),
    ("AppIcon-29x29@1x.png", 29),
    ("AppIcon-29x29@2x.png", 58),
    ("AppIcon-40x40@1x.png", 40),
    ("AppIcon-40x40@2x.png", 80),
    ("AppIcon-76x76@1x.png", 76),
    ("AppIcon-76x76@2x.png", 152),
    ("AppIcon-83.5x83.5@2x.png", 167),
    # App Store
    ("AppIcon-1024x1024@1x.png", 1024),
]

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def interpolate_color(color1, color2, factor):
    """Interpolate between two RGB colors"""
    r = int(color1[0] + (color2[0] - color1[0]) * factor)
    g = int(color1[1] + (color2[1] - color1[1]) * factor)
    b = int(color1[2] + (color2[2] - color1[2]) * factor)
    return (r, g, b)

def create_gradient_background(size, color1, color2):
    """Create vertical gradient background"""
    img = Image.new('RGB', (size, size), color1)
    draw = ImageDraw.Draw(img)
    
    for y in range(size):
        factor = y / size
        color = interpolate_color(color1, color2, factor)
        draw.line([(0, y), (size, y)], fill=color)
    
    return img

def draw_rounded_rect(draw, xy, radius, fill):
    """Draw rounded rectangle"""
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle([x1, y1, x2, y2], radius=radius, fill=fill)

def create_icon(size, output_path):
    """Create a single icon with gradient background and symbol"""
    # Indigo to teal gradient (matching Anji accent colors)
    color1 = hex_to_rgb("6366f1")  # Indigo
    color2 = hex_to_rgb("14b8a6")  # Teal
    
    # Create base image with gradient
    img = create_gradient_background(size, color1, color2)
    draw = ImageDraw.Draw(img)
    
    # Calculate proportions
    padding = size // 8
    inner_size = size - (padding * 2)
    
    # Draw card-like rounded rectangle in center (white with opacity effect)
    card_padding = size // 4
    card_size = size - (card_padding * 2)
    card_x = (size - card_size) // 2
    card_y = (size - card_size) // 2
    
    # Semi-transparent white card background
    overlay = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    overlay_draw = ImageDraw.Draw(overlay)
    corner_radius = size // 10
    overlay_draw.rounded_rectangle(
        [card_x, card_y, card_x + card_size, card_y + card_size],
        radius=corner_radius,
        fill=(255, 255, 255, 230)
    )
    
    # Composite overlay onto gradient
    img = img.convert('RGBA')
    img = Image.alpha_composite(img, overlay)
    
    # Draw symbol - "A" for Anji/Anki or memory symbol
    draw = ImageDraw.Draw(img)
    
    # Try to use a nice font, fallback to default
    try:
        # Try system fonts
        font_paths = [
            "/System/Library/Fonts/Helvetica.ttc",
            "/System/Library/Fonts/SF-Pro-Display-Bold.otf",
            "/Windows/Fonts/arialbd.ttf",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        ]
        font = None
        for fp in font_paths:
            if os.path.exists(fp):
                font_size = size // 2
                font = ImageFont.truetype(fp, font_size)
                break
        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # Draw "A" letter (for Anji/Anki)
    text = "A"
    
    # Get text bounding box
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Center the text
    x = (size - text_width) // 2
    y = (size - text_height) // 2 - (size // 20)  # Slight adjustment
    
    # Draw text with indigo color
    text_color = hex_to_rgb("4f46e5")  # Darker indigo for contrast
    draw.text((x, y), text, font=font, fill=text_color)
    
    # Convert to RGB for PNG (remove alpha for smaller file, or keep for transparency)
    final_img = Image.new('RGB', (size, size), (255, 255, 255))
    final_img.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)
    
    # Save
    final_img.save(output_path, 'PNG')
    print(f"Generated: {output_path} ({size}x{size})")

def main():
    # Get script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Output to AppIcon.appiconset
    output_dir = os.path.join(
        script_dir, '..', 'AnjiApp', 'Resources', 
        'Assets.xcassets', 'AppIcon.appiconset'
    )
    output_dir = os.path.abspath(output_dir)
    
    print(f"Output directory: {output_dir}")
    
    for filename, size in ICON_SPECS:
        output_path = os.path.join(output_dir, filename)
        create_icon(size, output_path)
    
    print(f"\n✅ Generated {len(ICON_SPECS)} app icons!")
    print(f"Location: {output_dir}")

if __name__ == "__main__":
    main()
