$fs=0.5;
size = [130, 55, 30];
wall_size = [2, 2, 2];
bar_size = [1000, 5.8, 16];
cable_slot_x = 70;
box_offset = [-size.x / 2, 0, 0];
box_bevel = 3;
inner_centre_y = bar_size.y + (size.y - bar_size.y) / 2;

peg_offset = [55, bar_size.y / 2]; // From front of box.
peg_dia = 2.8;
peg_height = 2;

screw_offset = [2.5, 2.5]; // From corner.
screw_post_width = 9;
screw_length = 9;
screw_hole_dia = 3.2;
screw_nut_depth = 5;
screw_nut_size = [5.5, 6.3, 2.8];

tripod_hole_dia = 8;
tripod_base = 1;
tripod_top_remove = 4;
tripod_extra_y = 2;
tripod_block_size = [12, 12, 5];

panel_length_back = 95;
panel_length_side = 12;
panel_height = 20;
panel_border = 2;
panel_wall = 2;
panel_thickness = 3;

use <threads.scad>

module centred_cube(size, centred = [1, 1, 0])
{
	c = centred;
	translate([c.x ? -size.x : 0, c.y ? -size.y : 0, c.z ? -size.z : 0] / 2)
	cube(size);
}

module box(height)
{
	b = box_bevel;

	translate(box_offset + [b, b, b]) 
	minkowski()
	{
		translate([0, 0, -b]) cylinder(r1 = 0, r2 = b, h = b, $fn = 4);
		cube([size.x - b * 2, size.y - b * 2, height - b]);
	}
}

module pegs()
{
	for (x = [-peg_offset.x, peg_offset.x])
		translate([x, peg_offset.y]) cylinder(d = peg_dia, h = peg_height);
}

module do_all_corners()
{
	module corner()
	{
		translate([size.x / 2 - wall_size.x, size.y - inner_centre_y - wall_size.y, 0]) // Inner corner.
		children();
	}
	
	translate([0, inner_centre_y, wall_size.z])
	{
		corner() children();
		mirror([0, 1, 0]) corner() children();
		mirror([1, 0, 0]) corner() children();
		mirror([1, 0, 0]) mirror([0, 1, 0]) corner() children();
	}
}

module screw_posts(height)
{
	points = [[-screw_post_width, 0], [0, 0], [0, 0 - screw_post_width]]; 
	do_all_corners() linear_extrude(height - wall_size.z) polygon(points);
}

module screw_holes(height)
{
	do_all_corners() 
	translate([-screw_offset.x, -screw_offset.y, height - screw_length]) 
	{
		cylinder(d = screw_hole_dia, h = screw_length + 1);
		
		rotate(135, [0, 0, 1])
		translate([-screw_nut_size.x / 2, -screw_nut_size.y / 2, screw_length - screw_nut_depth - screw_nut_size.z])
		cube(screw_nut_size + [0, 10, 0]);
	}
}

module tripod_hole()
{
	s = tripod_block_size;
	translate([0, bar_size.y + wall_size.y + s.y / 2, 0]) 
	{
		cylinder(d = tripod_hole_dia, h = wall_size.z);
		
		translate([0, -s.y / 2, tripod_base])
		centred_cube(s + [0, tripod_extra_y, 0], [1, 0, 0]);

		translate([0, s.y / 2 + tripod_extra_y, tripod_base])
		rotate(20, [1, 0, 0])
		centred_cube([s.x, wall_size.z * 2, wall_size.z], [1, 0, 0]);
	}
}

module tripod_top()
{
	t = 2;
	s = tripod_block_size;
	translate([0, bar_size.y + wall_size.y, tripod_base]) 
	centred_cube(s + [t * 2, -tripod_top_remove, t], [1, 0, 0]);
}

module tripod_block()
{
	s = tripod_block_size;
	
	difference()
	{
		centred_cube(s * 0.97);
		english_thread(diameter = 1/4, threads_per_inch = 20, length = s.z / 25.4, internal = true);
	}
}

module panel_block(width, hole)
{
	slot_size = [width + panel_border * 2, panel_thickness, panel_height + panel_border];
	block_size = [slot_size.x + panel_wall * 2, panel_thickness + panel_wall, size.z - wall_size.z];
	hole_size = [width, block_size.y + panel_wall + 2, panel_height];

	if (hole)
	{
		translate([0, -1, size.z - hole_size.z]) centred_cube(hole_size, [1, 0, 0]);
		translate([0, panel_wall, size.z - slot_size.z]) centred_cube(slot_size, [1, 0, 0]);
	}
	else
	{
		translate([0, panel_wall, size.z - block_size.z])
		centred_cube(block_size, [1, 0, 0]);
	}
}

module panel_blocks(hole)
{
	translate([0, size.y, 0]) rotate(180, [0, 0, 1]) panel_block(panel_length_back, hole);
	translate([size.x / 2, inner_centre_y, 0]) rotate(90, [0, 0, 1]) panel_block(panel_length_side, hole);
	translate([-size.x / 2, inner_centre_y, 0]) rotate(-90, [0, 0, 1]) panel_block(panel_length_side, hole);
}

module base()
{
	height = size.z;
	
	difference()
	{
		union()
		{
			difference()
			{
				box(height);
				
				// Main cavity.
				translate(box_offset + wall_size + [0, bar_size.y, 0]) cube(size - wall_size * 2 - [0, bar_size.y, -10]);

				// Lightbar recess.
				translate([-bar_size.x / 2, 0, height - bar_size.z]) cube(bar_size);
				
				// Lightbar cable slot.
				translate([-cable_slot_x / 2, 0, height - bar_size.z]) cube([cable_slot_x, bar_size.y, bar_size.z]);
			}
			
			translate([0, 0, height - bar_size.z]) pegs();
			
			screw_posts(height);
			
			tripod_top();

			panel_blocks(false);
		}

		screw_holes(height);

		tripod_hole();

		panel_blocks(true);
	}
}

module lid()
{
	difference()
	{
		union()
		{
			box(box_bevel * 2);
			translate([0, 0, box_bevel]) pegs();
		}
	}
}

module test()
{
	height = 12;
	difference()
	{
		cube([10, 10, height]);
		
		// Lightbar recess.
		translate([0, 0, height - bar_size.z / 2]) 
		cube(bar_size);
	}
	
	translate([5, peg_offset.y, height - bar_size.z / 2]) cylinder(d = peg_dia, h = peg_height);
}

module tripod_test()
{
	intersection()
	{
		base();

		translate([0, bar_size.y, 0]) 
		centred_cube(tripod_block_size + [5, 12, 3], [1, 0, 0]);
	}
}

base();
//lid();
//test();
//tripod_block();
//translate([20, 0, 0]) tripod_test();