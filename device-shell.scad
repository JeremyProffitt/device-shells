// Device Shell - Configurable 3D Model
// Format: [width, height, depth, horizontal_offset, vertical_offset]
// horizontal_offset: use "centered" for centering, or numeric value for offset from left
// vertical_offset: distance from ground (z=0)

// Shell configuration
shell_wall = 3;           // Wall thickness in mm
screw_hole_diameter = 3;  // Screw hole diameter in mm
shell_corner_radius = 2;  // Corner radius for bottom edges only
shell_height = 95;        // Shell height in mm

// AMP mounting hole pattern (4-hole rectangular pattern)
amp_hole_diameter = 3;        // Mounting hole diameter
amp_hole_spacing_x = 40;      // Horizontal spacing between holes
amp_hole_spacing_y = 30;      // Vertical spacing between holes

// Back ring configuration
ring_outer_diameter = 55;     // Outer diameter of ring
ring_inner_diameter = 45;     // Inner diameter of ring
ring_depth = 1;               // Depth of ring indentation

// Define all parts in an array - they will stack front to back automatically
// Format: [width, height, depth, horizontal_offset, vertical_offset]
parts = [
    // Part 1: LCD Opening - 5cm wide, 8cm high, 3mm deep, centered, 1cm off ground
    [50, 80, 3, "centered", 10],

    // Part 2: LCD Slot - 6cm wide, 9cm high, 2mm deep, centered, 5mm off ground
    [60, 90, 2, "centered", 5],

    // Part 3: LCD Slot Back - 5cm wide, 9cm high, 2mm deep, centered, 5mm off ground
    [50, 90, 2, "centered", 5],

    // Part 4: Main Area - 6cm wide, 9cm high, 4cm deep, centered, 5mm off ground
    [60, 90, 40, "centered", 5]
];

// Calculate maximum width from all parts
function max_part_width(parts, index=0) =
    index >= len(parts) ? 0 :
    max(parts[index][0], max_part_width(parts, index+1));

// Calculate total depth of all parts stacked
function total_parts_depth(parts, index=0) =
    index >= len(parts) ? 0 :
    parts[index][2] + total_parts_depth(parts, index+1);

// Calculate shell dimensions based on parts
shell_width = max_part_width(parts) + (3 * shell_wall) + (2 * screw_hole_diameter);
shell_depth = total_parts_depth(parts) + shell_wall;  // Front is flush with parts, wall only at back

// Calculate horizontal centering offset for shell
shell_x_offset = -shell_width / 2;

// Helper function to get horizontal offset
function get_x_offset(part, shell_width) =
    part[3] == "centered" ? (shell_width - part[0]) / 2 : part[3];

// Calculate cumulative depth offset for a part at given index
// Each part starts where the previous one ends (stacking front to back)
function cumulative_depth(parts, index) =
    index == 0 ? 0 : parts[index-1][2] + cumulative_depth(parts, index-1);

// Module to create a cube with rounded bottom edges only
module rounded_cube_bottom(width, height, depth, radius) {
    hull() {
        // Bottom corners with cylinders extending to full height
        translate([radius, radius, 0])
            cylinder(r=radius, h=height, $fn=20);
        translate([width-radius, radius, 0])
            cylinder(r=radius, h=height, $fn=20);
        translate([radius, depth-radius, 0])
            cylinder(r=radius, h=height, $fn=20);
        translate([width-radius, depth-radius, 0])
            cylinder(r=radius, h=height, $fn=20);
    }
}

// Module to create a cube with rounded top edges only (opposite of bottom)
module rounded_cube_top(width, height, depth, radius) {
    hull() {
        // Bottom corners - cylinders extending up to near top
        translate([radius, radius, 0])
            cylinder(r=radius, h=height - radius, $fn=20);
        translate([width-radius, radius, 0])
            cylinder(r=radius, h=height - radius, $fn=20);
        translate([radius, depth-radius, 0])
            cylinder(r=radius, h=height - radius, $fn=20);
        translate([width-radius, depth-radius, 0])
            cylinder(r=radius, h=height - radius, $fn=20);

        // Top corners - spheres for rounding
        translate([radius, radius, height - radius])
            sphere(r=radius, $fn=20);
        translate([width-radius, radius, height - radius])
            sphere(r=radius, $fn=20);
        translate([radius, depth-radius, height - radius])
            sphere(r=radius, $fn=20);
        translate([width-radius, depth-radius, height - radius])
            sphere(r=radius, $fn=20);
    }
}

// Module to create a negative part (cutout) with optional y-offset
module create_cutout(part, shell_width, y_offset=0) {
    width = part[0];
    height = part[1];
    depth = part[2];
    x_offset = get_x_offset(part, shell_width);
    z_offset = part[4];

    translate([x_offset, y_offset, z_offset])
        cube([width, depth, height]);
}

// Module to create all cutouts from parts array (stacked front to back)
module create_all_cutouts(parts, shell_width) {
    for (i = [0:len(parts)-1]) {
        y_offset = cumulative_depth(parts, i);
        create_cutout(parts[i], shell_width, y_offset);
    }
}

// Module for AMP mounting holes (4-hole rectangular pattern centered on back)
module amp_mounting_holes(center_x, center_y, center_z) {
    for (x_offset = [-amp_hole_spacing_x/2, amp_hole_spacing_x/2]) {
        for (z_offset = [-amp_hole_spacing_y/2, amp_hole_spacing_y/2]) {
            translate([center_x + x_offset, center_y - shell_wall - 1, center_z + z_offset])
                rotate([-90, 0, 0])
                    cylinder(d=amp_hole_diameter, h=shell_wall + 2, $fn=20);
        }
    }
}

// Module for ring on back (1mm deep indentation with chamfered edges)
module back_ring(center_x, center_y, center_z) {
    chamfer_size = 0.5;  // Chamfer size in mm

    translate([center_x, center_y - ring_depth, center_z])
        rotate([-90, 0, 0])
            difference() {
                // Outer chamfered cylinder (55mm outer diameter)
                hull() {
                    cylinder(d=ring_outer_diameter, h=0.01, $fn=60);
                    translate([0, 0, ring_depth - 0.01])
                        cylinder(d=ring_outer_diameter - 2*chamfer_size, h=0.01, $fn=60);
                }
                // Subtract inner chamfered cylinder (45mm inner diameter)
                hull() {
                    translate([0, 0, -0.5])
                        cylinder(d=ring_inner_diameter, h=0.01, $fn=60);
                    translate([0, 0, ring_depth - 0.01])
                        cylinder(d=ring_inner_diameter + 2*chamfer_size, h=0.01, $fn=60);
                }
            }
}

// Main model - shell with cutouts and screw holes
difference() {
    // Main shell with rounded bottom edges, horizontally centered
    translate([shell_x_offset, 0, 0])
        rounded_cube_bottom(shell_width, shell_height, shell_depth, shell_corner_radius);

    // Union all parts (automatically stacked front to back)
    // Parts are flush with the front of the shell (no front wall)
    translate([shell_x_offset, 0, 0])
        union() {
            create_all_cutouts(parts, shell_width);
        }

    // Screw holes - left and right, centered front to back
    // Left screw hole
    translate([shell_x_offset + shell_wall + screw_hole_diameter/2,
               shell_depth/2,
               0])
        cylinder(d=screw_hole_diameter, h=shell_height, $fn=20);

    // Right screw hole
    translate([shell_x_offset + shell_width - shell_wall - screw_hole_diameter/2,
               shell_depth/2,
               0])
        cylinder(d=screw_hole_diameter, h=shell_height, $fn=20);

    // AMP mounting holes and ring on back (centered)
    amp_mounting_holes(shell_x_offset + shell_width/2, shell_depth, shell_height/2);
    back_ring(shell_x_offset + shell_width/2, shell_depth, shell_height/2);
}

// Back plate - separate object 5mm behind the shell
// Same width and depth as shell, shell_wall tall (thin horizontal plate)
translate([shell_x_offset, shell_depth + 5, 0])
    difference() {
        rounded_cube_top(shell_width, shell_wall, shell_depth, shell_corner_radius);

        // Left screw hole (matching shell position)
        translate([shell_wall + screw_hole_diameter/2,
                   shell_depth/2,
                   0])
            cylinder(d=screw_hole_diameter, h=shell_wall, $fn=20);

        // Right screw hole (matching shell position)
        translate([shell_width - shell_wall - screw_hole_diameter/2,
                   shell_depth/2,
                   0])
            cylinder(d=screw_hole_diameter, h=shell_wall, $fn=20);
    }
