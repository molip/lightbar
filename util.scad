module centred_cube(size, centred = [1, 1, 0])
{
	c = centred;
	translate([c.x ? -size.x : 0, c.y ? -size.y : 0, c.z ? -size.z : 0] / 2)
	cube(size);
}

module centred_cube_x(size)
{
	centred_cube(size, [1, 0, 0]);
}

module centred_cube_y(size)
{
	centred_cube(size, [0, 1, 0]);
}