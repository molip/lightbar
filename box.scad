$fs=0.5;
size = [140, 58, 35];
wall_size = [2, 2, 2];
bar_size = [1000, 5.8, 16];
cable_slot_x = 70;
box_offset = [-size.x / 2, 0, 0];
box_bevel = 3;
inner_centre_y = bar_size.y + (size.y - bar_size.y) / 2;

peg_spacing_top = 80;
peg_spacing_bottom = 100;
peg_dia = 2.8;
peg_height = 2;

screw_offset = [5, 5]; // From corner.
screw_post_width = 14;
screw_length = 9;
screw_hole_dia = 3.2;
screw_nut_depth = 5;
screw_nut_size = [5.5, 6.3, 2.8];

tripod_hole_dia = 8;
tripod_base = 1;
tripod_top_remove = 4;
tripod_extra_y = 2;
tripod_block_size = [12, 12, 5];
tripod_hole_y = size.y / 2;

panel_length_back = 110;
panel_length_side = 20;
panel_height = 20;
panel_border = 2;
panel_wall = 2;
panel_thickness = 2;

use <threads.scad>
use <util.scad>
use <controls.scad>

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

module pegs(spacing)
{
	for (x = [-spacing / 2, spacing / 2])
		translate([x, bar_size.y / 2]) cylinder(d = peg_dia, h = peg_height);
}

module do_all_corners(bottom)
{
	module corner()
	{
		translate([size.x / 2 - wall_size.x, size.y - inner_centre_y - wall_size.y, 0]) // Inner corner.
		children();
	}
	
	translate([0, inner_centre_y, bottom])
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
	do_all_corners(wall_size.z) linear_extrude(height - wall_size.z) polygon(points);
}

module screw_holes(height)
{
	do_all_corners(wall_size.z) 
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
	translate([0, tripod_hole_y, 0]) 
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
	translate([0, tripod_hole_y - s.y / 2, tripod_base]) 
	centred_cube(s + [t * 4, -tripod_top_remove, t], [1, 0, 0]);
}

module tripod_block()
{
	s = tripod_block_size;
	
	difference()
	{
		mm_per_in = 25.4;
		dia = 1/4 + 0.2 / mm_per_in; 
		centred_cube(s * 0.95);
		english_thread(diameter = dia, threads_per_inch = 20, length = s.z / mm_per_in, internal = true);
	}
}

module panel_block(width, top, height, hole)
{
	slot_size = [width + panel_border * 2, panel_thickness, height + panel_border];
	block_size = [slot_size.x + panel_wall * 2, panel_thickness + panel_wall, top - wall_size.z];
	hole_size = [width, block_size.y + panel_wall + 2, height];

	if (hole)
	{
		translate([0, -1, top - hole_size.z]) centred_cube(hole_size, [1, 0, 0]);
		translate([0, panel_wall, top - slot_size.z]) centred_cube(slot_size, [1, 0, 0]);
	}
	else
	{
		translate([0, panel_wall, top - block_size.z])
		centred_cube(block_size, [1, 0, 0]);
	}
}

module panel_blocks(hole, top, height)
{
	translate([0, size.y, 0]) rotate(180, [0, 0, 1]) panel_block(panel_length_back, top, height, hole);
	translate([size.x / 2, inner_centre_y, 0]) rotate(90, [0, 0, 1]) panel_block(panel_length_side, top, height, hole);
	translate([-size.x / 2, inner_centre_y, 0]) rotate(-90, [0, 0, 1]) panel_block(panel_length_side, top, height, hole);
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
				translate([-cable_slot_x / 2, 0, height - bar_size.z]) cube([cable_slot_x, bar_size.y + wall_size.y, bar_size.z]);
			}
			
			translate([0, 0, height - bar_size.z]) pegs(peg_spacing_bottom);
			
			screw_posts(height);
			
			tripod_top();

			panel_blocks(false, height, panel_height);
		}

		screw_holes(height);

		tripod_hole();

		panel_blocks(true, height, panel_height);
	}
}

module lid()
{
	height = box_bevel + 2;

	difference()
	{
		union()
		{
			box(height);
			translate([0, 0, height]) pegs(peg_spacing_top);
		}
		
		panel_blocks(true, height, 0);
		
		do_all_corners(0) 
		translate([-screw_offset.x, -screw_offset.y, 0]) 
		{
			cylinder(d = screw_hole_dia, h = height);
			cylinder(d = 6, h = 2);
		}
	}
}

module spare_peg()
{
	cylinder(d = peg_dia, h = peg_height + 2);
}

module side_panel(remote)
{
	difference()
	{
		border = [panel_border, panel_border, 0];
		shrink = [0.2, 0.2, 0.25];
		centred_cube([panel_length_side, panel_height, panel_thickness] + border * 2 - shrink);
		x = remote ? 4.5 : -4.5;
		translate([x, -4.5, 0]) cylinder(d = 6.2, h = panel_thickness);
		if (remote)
			translate([-4.5, 4.5, 0]) cylinder(d = 6, h = panel_thickness);
	}
}

module back_panel()
{
	module controls(hole)
	{
		translate([7, -4.8, 0]) control_jack_socket(hole);

		translate([43, 0, 0]) 
		{
			translate([0, 5, 0]) control_tactile(6, 1, hole);

			if (hole) // Icon trough.
				translate([0, -4, 0]) centred_cube([6 * 4 * 2.54, 8, 1]);
		}
		translate([84, 0, 0]) control_toggle_button(hole);

		translate([103, 0, 0]) control_power_socket(hole);
	}

	border = [panel_border, panel_border, 0];
	shrink = [0.2, 0.2, 0.2];
	size = [panel_length_back, panel_height, panel_thickness] + border * 2 - shrink;

	difference()
	{
		$thickness = size.z;

		union()
		{
			translate([0, -size.y / 2, 0]) cube(size);
			controls(false);
		}
		
		controls(true);
	}
}

module pcb_block()
{
	board = [71, 1.7, 7];
	base = 2;
	wall = 3;
	back = 7;
	
	difference()
	{
		all = [board.x + wall * 2, back + board.y + wall, base + board.z];
		centred_cube(all, [1, 0, 0]);
		translate([0, 0, base + 1]) centred_cube(all - [14, 0, 0], [1, 0, 0]);
		translate([0, wall, base]) centred_cube(board, [1, 0, 0]);
		
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
//spare_peg();
//translate([20, -30, 0]) side_panel(false);
//translate([50, -30, 0]) side_panel(true);
//back_panel();
//pcb_block();