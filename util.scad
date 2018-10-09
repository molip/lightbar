module centred_cube(size, centred = [1, 1, 0])
{
	c = centred;
	translate([c.x ? -size.x : 0, c.y ? -size.y : 0, c.z ? -size.z : 0] / 2)
	cube(size);
}
