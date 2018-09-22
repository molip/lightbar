$fn=16;
size = [120, 50, 30];
wall_size = [3, 3, 3];
bar_size = [1000, 5.8, 16];
cable_slot_x = 70;
box_offset = [-size.x / 2, 0, 0];
box_bevel = 3;
inner_centre_y = bar_size.y + (size.y - bar_size.y) / 2;

peg_offset = [55, bar_size.y / 2]; // From front of box.
peg_dia = 2.8;
peg_height = 2;

screw_offset = [5, 5]; // From corner.
screw_post_width = 8;
screw_length = 10;
screw_hole_dia = 3.2;
screw_nut_depth = 6;
screw_nut_size = [5, 5, 2];

// X,Y centred on origin.
module bevel(amount, size)
{
	module side(x, y)
	{
		translate([-x / 2, y / 2 - amount, 0])
		rotate(-45, [1, 0, 0])
		cube([x, amount * 2, amount * 2]);

		translate([-x / 2 + amount, y / 2 - amount, 0])
		rotate(45, [0, 0, 1])
		rotate(-atan(sqrt(2) / 2), [1, 0, 0])
		translate([-amount * 2, 0, 0])
		cube(amount * 4);

		translate([-x / 2, y / 2 - amount, 0])
		rotate(45, [0, 0, 1])
		cube([amount * 2, amount * 2, size.z]);

	}
	
	for (a = [0, 180])
	{
		rotate(a, [0, 0, 1]) side(size.x, size.y);
		rotate(a + 90, [0, 0, 1]) side(size.y, size.x);
	}
}

module box(height)
{
	translate(box_offset) 
	cube([size.x, size.y, height]);
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
	translate([-screw_hole_dia / 2, -screw_hole_dia / 2, height - screw_length]) 
	{
		cylinder(d = screw_hole_dia, h = screw_length + 1);
		
		rotate(135, [0, 0, 1])
		translate([-screw_nut_size.x / 2, -screw_nut_size.y / 2, screw_length - screw_nut_depth - screw_nut_size.z])
		cube(screw_nut_size + [0, 10, 0]);
	}
}

module base()
{
	height = size.z - box_bevel;

	difference()
	{
		union()
		{
			difference()
			{
				box(height);
				
				// Main cavity.
				translate(box_offset + wall_size + [0, bar_size.y, 0]) cube(size - wall_size * 2 - [0, bar_size.y, 0]);

				// Lightbar recess.
				translate([-bar_size.x / 2, 0, height - bar_size.z]) cube(bar_size);
				
				// Lightbar cable slot.
				translate([-cable_slot_x / 2, 0, height - bar_size.z]) cube([cable_slot_x, bar_size.y, bar_size.z]);
			}
			
			translate([0, 0, height - bar_size.z]) pegs();
			
			screw_posts(height);
		}

		screw_holes(height);

		translate([0, size.y / 2, 0]) bevel(box_bevel, size);
	}
}

module lid()
{
	difference()
	{
		union()
		{
			box(box_bevel);
			translate([0, 0, box_bevel]) pegs();
		}
		
		translate([0, size.y / 2, 0]) bevel(box_bevel, size);
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

base();
//lid();
//test();
