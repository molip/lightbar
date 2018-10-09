$fs=0.5;
add = 0.2;

use <util.scad>

// 16mm
module control_push_button(hole)
{
	if (hole)
	{
		dia = 12.7 + add;
		flat = 5.5 + add;

		linear_extrude(height = $thickness)
		difference()
		{
			circle(d=dia);
			translate([flat, -dia / 2, 0]) square(dia);
		}
	}
}

// 16mm
module control_power_socket(hole)
{
	if (hole)
	{
		dia = 12.6 + add;
		flat_width = 11.6 + add;

		linear_extrude(height = $thickness)
		intersection()
		{
			circle(d=dia);
			square([flat_width, dia], center = true);
		}
	}
}

// 18mm
module control_toggle_button(hole)
{
	if (hole)
	{
		dia = 15.2 + add;
		notch = [8.5 + add, 2.0 + add];

		linear_extrude(height = $thickness)
		{
			circle(d=dia);
			translate([0, -notch.y / 2, 0]) square(notch);
		}
	}
}

// 17mm
module control_pot(hole)
{
	dia = 6.8 + add;
	extra = 1;
	depth = $thickness + extra;
	peg = 2;
	hole_size = [1.2 + add, 2.8 + add, peg];
	offset = 7.8;
	rim = 2;

	if (hole)
	{
		cylinder(d = dia, h = depth);
		translate([-offset, 0, depth - peg]) centred_cube(hole_size);
	}
	else
	{
		cylinder(d = dia + rim * 2, h = depth);
		translate([-offset, 0, 0]) centred_cube([hole_size.x + rim, hole_size.y + rim, depth]);
	}
}

module control_tactile(nx, ny, hole, icons)
{
	height = 12;
	protrude = 1;
	board_thickness = 1.65;
	dot_pitch = 2.54;
	switch_dots = [3, 2];
	gap_dots = [1, 2];

	hole_dia = 4.7;

	depth_min = height - protrude - $thickness - board_thickness;
	
	total_switch_dots = [(switch_dots.x + gap_dots.x) * nx, (switch_dots.y + gap_dots.y) * ny] - gap_dots;
	
	module posts(dia)
	{
		dx = (1 + total_switch_dots.x / 2) * dot_pitch;
		for (x = [-dx, dx])
			translate([x, 0, $thickness])
				cylinder(d = dia, h = depth_min);
	}
	
	if (hole)
	{
		translate((switch_dots - total_switch_dots) / 2 * dot_pitch)
		for (x = [0 : nx - 1])
			for (y = [0 : ny - 1])
			{
				translate([x * (switch_dots.x + gap_dots.x), y * (switch_dots.y + gap_dots.y)] * dot_pitch) 
				{
					cylinder(d = hole_dia, h = $thickness);
					translate([0, -hole_dia /2 - 6, 0])
					mirror([0, 1, 0])
					linear_extrude(height = 0.5) import(icons[y][x]);
				}
			}

		posts(2.1);
	}
	else
	{
		posts(5.5);
	}
}

