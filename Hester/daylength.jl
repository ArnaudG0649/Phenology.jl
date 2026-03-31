using PeriodicARModels

const DEG2RAD = π / 180.0

"""
    daylength_cbm(Lat, t; p=0.833)

Compute daylength (hours) using the CBM model.

Parameters
----------
Lat : latitude in degrees (North positive)
t   : day of year (1–365)
p   : sun angle below horizon in degrees
      (default = 0.833, official sunrise/sunset)

Returns
-------
Daylength in hours (Float64)
"""
function daylength_cbm(Lat, t::Integer; p=0.833)
    # Convert to radians 
    L_rad = Lat * DEG2RAD
    p_rad = p * DEG2RAD

    θ = 0.2163108 + 2.0 * atan(0.9671396 * tan(0.00860 * (t - 186.0)))
    Φ = asin(0.39795 * cos(θ))

    # Argument of arccos
    arg = (sin(p_rad) + sin(L_rad) * sin(Φ)) /
          (cos(L_rad) * cos(Φ))

    # Handle polar day / night
    if arg ≥ 1.0
        return 24.0        # continuous daylight
    elseif arg ≤ -1.0
        return 0.0         # continuous darkness
    else
        return 24.0 - (24.0 / π) * acos(arg)    # Daylength formula
    end
end
daylength_cbm(Lat, date::Date; p=0.833) = daylength_cbm(Lat, dayofyear_Leap(date); p=p)