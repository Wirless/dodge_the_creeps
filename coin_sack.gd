extends Node2D

func _draw():
    # Draw sack shape
    var points = PackedVector2Array([
        Vector2(0, 0),          # Top left
        Vector2(40, 0),         # Top right
        Vector2(50, 20),        # Right bulge
        Vector2(40, 40),        # Bottom right
        Vector2(20, 50),        # Bottom middle
        Vector2(0, 40),         # Bottom left
        Vector2(-10, 20),       # Left bulge
        Vector2(0, 0)           # Back to top
    ])
    
    # Draw sack fill
    draw_colored_polygon(points, Color(0.6, 0.4, 0.2))  # Brown color
    
    # Draw sack outline
    draw_polyline(points, Color(0.4, 0.2, 0.1), 2.0)  # Darker brown outline
    
    # Draw rope tie
    draw_line(Vector2(15, 0), Vector2(25, 0), Color(0.4, 0.2, 0.1), 2.0)
    draw_line(Vector2(20, 0), Vector2(20, -5), Color(0.4, 0.2, 0.1), 2.0)