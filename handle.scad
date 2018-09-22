$fn=20;
handle_length = 80;
handle_dia = 30;
sides = 8;
recess_depth = 10;
recess_dia = 10;
slot_depth = 3;
slot_dia = 18;
conn_depth = 15;
conn_dia = 13;
motor_depth = 3.4;
motor_dia = 10.2;

panel_scale = 0.97;
panel_hole_dia = 6.2;
 
module slot()
{
	rotate(180 / sides, [0, 0, 1]) cylinder(h = slot_depth, d = slot_dia, $fn = sides);
}

module common()
{
	difference()
	{
		hull()
		{
			rad = handle_dia / 6;
			for (a = [0 : 1 + sides / 2])
			{
				rotate(360 * (a - 0.5) / sides, [0, 0, 1])
				translate([handle_dia / 2 - rad, 0, 0])
					hull()
						for (z = [rad, handle_length - rad])
							translate([0, 0, z]) sphere(r = rad, $fn = 32);
			}	
		}
		
		translate([-handle_dia / 2, -handle_dia, 0]) cube([handle_dia, handle_dia, handle_length]);
		
		cylinder(d = recess_dia, h = recess_depth);
		
		translate([0, 0, recess_depth])
		{
			slot();

			// conn_depth includes slot_depth.
			cylinder(d = conn_dia, h = conn_depth);
		}
	}
}

module base()
{
	module screw()
	{
		screw_depth = 8;
		nut_depth = 3;
		nut_thickness = 2.5;
		nut_min = 5.5;
		nut_max = 6.3;
		
		rotate(-90, [1, 0, 0])
		{
			cylinder(d = 3.1, h = screw_depth);
		}

		translate([-nut_min / 2, nut_depth, -nut_max / 2]) cube([nut_min, nut_thickness, nut_max]);
		
		translate([-nut_min / 2, 0, nut_max / 2]) cube([nut_min, nut_depth + nut_thickness, nut_max]);
		
	}

	difference()
	{
		common();
	
		translate([0, 0, 30]) screw();
		
		translate([0, 0, 50]) rotate(-90, [1, 0, 0]) cylinder(d = motor_dia, h = motor_depth);
		
		translate([4.5, 0, 23]) cube([3, motor_depth, 28]);
		
		translate([0, 0, handle_length - 10]) rotate(180, [0, 1, 0]) screw();
	}
}

module panel()
{
	difference()
	{
		scale(panel_scale) slot();
		cylinder(d = panel_hole_dia, h = slot_depth);
	}	
}

rotate(90, [1, 0, 0]) 
base();

//translate([30, 0, 0]) 
//panel();
