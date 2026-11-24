/*
  Dock with the NFC reader built in, plus a pocket for the NFC card box. ONE printed part.
  The reader half is the unchanged base of nfc-reader-case.scad, fused into the plate, so the
  existing lid (nfc-case-lid-print-v13 / -plain-v13) clicks on exactly as before.

  Keep nfc-reader-case.scad in the same folder as this file: the reader geometry is taken from it,
  so any change you make there (board sizes, posts, snap fit) carries over to this dock.

  Prints flat, floor down, no supports.   openscad -o nfc-dock-integrated.stl nfc-dock-integrated.scad

  Layout seen from above, front (towards you) at the bottom:

      +---------+ +-----------+
      |         | |           |
      | reader  | | card box  |
   USB|         | |           |
      |         | +-----------+
      |         |   free area (engraving)
      +---------+
  The reader is on the left, "portrait", USB opening on the left-hand side, ESP32 bay at the back.
  The card box is on the right, against the back. Reader and card box are both exactly "edge"
  away from the outside of the dock.
*/
use <nfc-reader-case.scad>

plate_h      = 4.0;   // plate thickness
round_plate = true;   // true = round plate; false = rounded rectangle following the items
plate_round = 2.0;    // rounded top edge of the plate (round plate only). 0 = sharp
reader_fillet = 2.5;  // rounded (concave) transition from the plate up into the reader walls. 0 = sharp.
                      // Keep it below gap - clr (2.7) so it stops just short of the card box pocket.
round_rim   = 5.0;    // round plate: rim at the closest point (the outer corners of reader and card box)

box_pocket_d = 2.0;   // card box pocket depth
clr          = 0.3;   // clearance around the card box in its pocket, per side
edge         = 3.0;   // distance from the reader walls AND from the card box walls to the outside of the dock
gap          = 3.0;   // plate between the reader wall and the card box wall (same as edge = one even band everywhere)
chamfer      = 0;     // lead-in chamfer on the card box pocket rim. 0 keeps the band crisp (a chamfer makes
                      // the band next to the box look ~0.6 mm narrower than next to the reader)
reader_lift  = 1.0;   // the reader's underside is this far above the table. Its USB opening starts 3 mm higher,
                      // so with 1.0 the opening starts level with the top of the 4 mm rim. Do not go below 1.0
                      // unless you also lower plate_h. (The loose reader in the first dock sat at 2.0.)

// optional engraving in the free area in front of the card box, readable from the front
pocket_text   = ["braham2019", "v1.0"];   // lines engraved in the floor of the card box pocket (hidden under the box). [] = none
pocket_text_size  = 5;     // first line
pocket_text_size2 = 3.5;   // following lines (version), a bit smaller
pocket_text_lead  = 1.5;   // line spacing as a multiple of the text size
pocket_text_depth = 0.6;
engrave_text  = "";   // "" = nothing
engrave_size  = 8;    // letter height
engrave_depth = 0.6;
engrave_font  = "Liberation Sans:style=Bold";

// card box footprint (nfc-card-box.scad)
box_w = 59.2;  box_d = 77.3;  box_r = 2.5;   // deep box (was 55.0)

// reader base footprint, must match nfc-reader-case.scad (see its "outer size" echo)
rd_long = 77.3;  rd_short = 45.0;  rd_r = 2.0;  rd_wall = 2.0;

full_box = box_d >= rd_long - 0.01;   // box as deep as the reader: right-hand corners follow the box
pb_w = box_w + 2*clr;  pb_d = box_d + 2*clr;      // pocket size
rd_x = edge;                                       // left outer face of the reader
pb_x = rd_x + rd_short + gap - clr;                // left edge of the card box pocket (box wall is "gap" from the reader)
out_w = pb_x + pb_w - clr + edge;                  // card box wall is "edge" from the right-hand side
out_d = edge + max(box_d, rd_long) + edge;
box_centered = true;   // true = card box centred front-to-back; false = against the back (3 mm rim)
// round plate: circle centred on the reader + card box group, just big enough to keep round_rim
// around the farthest corner arcs (reader corners r = rd_r, card box corners r = box_r)
rnd_cx = (rd_x + pb_x + clr + box_w) / 2;
rnd_cy = out_d / 2;
rnd_far_rd  = norm([rnd_cx - (rd_x + rd_r), rnd_cy - (edge + rd_r)]) + rd_r;
rnd_far_box = norm([(pb_x + clr + box_w - box_r) - rnd_cx, (out_d - edge - box_r) - rnd_cy]) + box_r;
rnd_r = max(rnd_far_rd, rnd_far_box) + round_rim;
pb_y = box_centered ? (out_d - pb_d) / 2
                    : out_d - edge + clr - pb_d;   // card box wall is "edge" from the back
$fn = 48;

function sum_to(v, k) = k <= 0 ? 0 : v[k] + sum_to(v, k - 1);

module rr(w, d, r) { hull() for (x = [r, w - r], y = [r, d - r]) translate([x, y]) circle(r = r); }

// Outer outline. Each corner is concentric with the corner of the item next to it, so the band
// stays "edge" wide around the corners too: reader corners r = 2 + edge, card box corner r = 2.5 + edge.
module outline() {
  if (round_plate) translate([rnd_cx, rnd_cy]) circle(r = rnd_r, $fn = 180);
  else rect_outline();
}

module rect_outline() {
  rs = [[rd_r + edge, rd_r + edge],                    // front-left  (reader)
        [rd_r + edge, out_d - rd_r - edge],            // back-left   (reader)
        full_box ? [out_w - box_r - edge, box_r + edge]
                 : [out_w - rd_r - edge, rd_r + edge],             // front-right
        (box_centered && !full_box) ? [out_w - rd_r - edge, out_d - rd_r - edge]   // back-right (same as the others)
                     : [out_w - box_r - edge, out_d - box_r - edge]]; // back-right (card box in the corner)
  rad = [rd_r + edge, rd_r + edge, full_box ? box_r + edge : rd_r + edge,
         (box_centered && !full_box) ? rd_r + edge : box_r + edge];
  hull() for (i = [0:3]) translate(rs[i]) circle(r = rad[i]);
}

module pocket(w, d, r, depth) {
  translate([0, 0, plate_h - depth]) linear_extrude(height = depth + 0.01) rr(w, d, r);
  if (chamfer > 0)
    translate([0, 0, plate_h - chamfer]) hull() {
      linear_extrude(height = 0.01) rr(w, d, r);
      translate([-chamfer, -chamfer, chamfer]) linear_extrude(height = 0.01) rr(w + 2*chamfer, d + 2*chamfer, r + chamfer);
    }
}

// the reader base, turned portrait: USB opening to the left, ESP32 bay to the back
// concave fillet around the foot of the reader walls, built from lofted slices of the reader outline
module reader_fillet_solid() {
  n = 12;
  translate([rd_x, edge, plate_h - 0.01])
    for (i = [0 : n - 1]) {
      z1 = reader_fillet * i / n;  z2 = reader_fillet * (i + 1) / n;
      d1 = reader_fillet - sqrt(reader_fillet^2 - (reader_fillet - z1)^2);
      d2 = reader_fillet - sqrt(reader_fillet^2 - (reader_fillet - z2)^2);
      hull() {
        translate([0, 0, z1]) linear_extrude(height = 0.01) offset(r = d1) rr(rd_short, rd_long, rd_r);
        translate([0, 0, z2]) linear_extrude(height = 0.01) offset(r = d2) rr(rd_short, rd_long, rd_r);
      }
    }
}

module reader_base() {
  translate([rd_x + rd_short, edge, reader_lift]) rotate([0, 0, 90]) translate([rd_wall, rd_wall, 0]) base();
}

union() {
  difference() {
    if (round_plate && plate_round > 0)
      translate([rnd_cx, rnd_cy, 0]) rotate_extrude($fn = 180)
        hull() {
          square([rnd_r, plate_h - plate_round]);
          square([rnd_r - plate_round, plate_h]);
          translate([rnd_r - plate_round, plate_h - plate_round]) circle(r = plate_round, $fn = 32);
        }
    else linear_extrude(height = plate_h) outline();
    translate([pb_x, pb_y, 0]) pocket(pb_w, pb_d, box_r + clr, box_pocket_d);
    // room for the reader: the plate stops inside the reader's walls and just inside its floor
    // (0.5 mm / 0.2 mm overlap so the parts fuse into one solid)
    translate([rd_x + 0.5, edge + 0.5, reader_lift + 0.2]) linear_extrude(height = plate_h + 2) rr(rd_short - 1, rd_long - 1, rd_r);
    // line i: baseline steps of size * lead; the block is centred in the pocket
    let (n = len(pocket_text),
         sz = [for (i = [0 : n - 1]) i == 0 ? pocket_text_size : pocket_text_size2],
         step = [for (i = [0 : n - 1]) i == 0 ? 0 : (sz[i - 1] + sz[i]) / 2 * pocket_text_lead],
         off = [for (i = [0 : n - 1]) i == 0 ? 0 : -(sum_to(step, i))],
         mid = off[n - 1] / 2)
    for (i = [0 : n - 1])
      translate([pb_x + pb_w/2, pb_y + pb_d/2 + off[i] - mid, plate_h - box_pocket_d - pocket_text_depth])
        linear_extrude(height = pocket_text_depth + 0.01)
          text(pocket_text[i], size = sz[i], halign = "center", valign = "center", font = engrave_font);
    if (engrave_text != "")
      translate([pb_x + pb_w/2, box_centered ? pb_y/2 + 1 : pb_y/2, plate_h - engrave_depth]) linear_extrude(height = engrave_depth + 0.01)
        text(engrave_text, size = engrave_size, halign = "center", valign = "center", font = engrave_font);
  }
  reader_base();
  // fillet, kept out of the reader's inside and away from the USB opening
  if (reader_fillet > 0)
    difference() {
      reader_fillet_solid();
      translate([rd_x + 0.5, edge + 0.5, 0]) linear_extrude(height = 50) rr(rd_short - 1, rd_long - 1, rd_r);
      intersection() {
        translate([rd_x + rd_short, edge, reader_lift]) rotate([0, 0, 90]) translate([rd_wall, rd_wall, 0]) usb_keepout(10);
        translate([-50, -50, plate_h]) cube([300, 300, 50]);
      }
    }
}

echo(round_plate ? str("round dock: diameter ", 2*rnd_r) : "");
echo(str("dock: ", out_w, " x ", out_d, "   plate ", plate_h, " high, reader top at ", reader_lift + 12.9, " (", reader_lift + 14.5, " with the lid)"));
echo(str("card box wall to front edge: ", pb_y + clr, "  to back edge: ", out_d - pb_y - pb_d + clr));
if (reader_lift + 3 < plate_h) echo("WARNING: the rim is higher than the bottom of the USB opening");
