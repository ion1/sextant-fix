# Construct a quaternion corresponding to moving vectors toward the given
# azimuth on the surface of a sphere.
# q: A quaternion representing the rotation corresponding to the movement
# location: The vector at which the azimuth is evaluated
# distance: The distance on the surface of the the sphere in radians
function q = azimuth_rotation(location, azimuth, distance)
  axis = azimuth_rotation_axis(location, azimuth);
  q = rot2q(axis, distance);
endfunction
