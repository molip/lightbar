$fs=0.5;
handle_length = 80;
handle_dia = 30;
sides = 8;
recess_depth = 10;
recess_dia = 10;
slot_depth = 3;
slot_dia = 18;
conn_depth = 13;
conn_dia = 13;
motor_depth = 3.4;
motor_dia = 10.2;
motor_y = 42;
wire_slot = 3;

panel_scale = 0.97;
panel_hole_dia = 6.2;

screw_1 = 27;
screw_2 = handle_length - 10;
screw_dia = 3.2;
 
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
		nut_thickness = 3;
		nut_min = 5.5;
		nut_max = 6.3;
		
		rotate(-90, [1, 0, 0])
		{
			cylinder(d = screw_dia, h = screw_depth);
		}

		// Nut slot.
		translate([-nut_min / 2, nut_depth, -nut_max / 2]) cube([nut_min, nut_thickness, nut_max]);
		
		// Access hole.
		translate([-nut_min / 2, 0, nut_max / 2]) cube([nut_min, nut_depth + nut_thickness, nut_max - 1]);
		
	}

	difference()
	{
		common();
	
		translate([0, 0, screw_1]) screw();
		
		translate([0, 0, motor_y]) rotate(-90, [1, 0, 0]) cylinder(d = motor_dia, h = motor_depth);
		
		wire_x = 7;
		h_wire_2_width = 5;
		wire_z = recess_depth + conn_depth - h_wire_2_width;
		
		// H wire top.
		translate([0, 0, motor_y - wire_slot / 2]) cube([wire_x + wire_slot, motor_depth, wire_slot]);
		
		// V wire.
		translate([wire_x, 0, wire_z]) cube([wire_slot, motor_depth, motor_y - wire_z]);

		// H wire bottom.
		translate([0, 0, wire_z]) cube([wire_x + wire_slot, motor_depth, h_wire_2_width]);
		
		translate([0, 0, screw_2]) rotate(180, [0, 1, 0]) screw();
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
