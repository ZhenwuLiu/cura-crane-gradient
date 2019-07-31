# cura_crane_gradient

This is a quick and dirty Ruby script that will modify Cura-generated gcode to add color gradients for the Crane QuadFusion 3D printer family

## Usage

```
ruby cura-crane-gradient.rb in.gcode POINT [POINT...] > out.gcode
```
where POINT is e.g. `13P0:0:1:0` (third filament at 13 percent) or `112L0:1:0:0` (second filament at layer 112). all filament mixes at each given point must sum to 1

