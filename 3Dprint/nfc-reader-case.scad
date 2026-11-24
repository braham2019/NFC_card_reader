/*
  NFC album reader case: PN532 V3 module + Seeed Studio XIAO ESP32C3
  Flat "coaster" style: the card is tapped on the lid, above the PN532 antenna.

  Units: mm.  Choose what to render with:  part = "base" | "lid" | "assembly" | "boards"
  Command line example:  openscad -D 'part="base"' -o base.stl nfc-reader-case.scad

  Values marked (ASSUMED) come from product photos/listings, not from calipers.
  Measure your own boards and adjust before printing.
*/

part = "assembly";

// ---------------- emblem on the lid (marks the tap spot) ----------------
emblem_mode = "recess";  // "recess" = engraved into the lid (prints cleanly, outer face on the bed)
                         // "raised" = embossed. Only print this with the OUTER face UP (needs supports
                         //           under the lip and pegs); face down it would rest on the emblem.
emboss_h   = 0;      // depth (recess) or height (raised) of the emblem. 0 = no emblem (plain lid, the default now)
emblem_w   = 24;     // emblem width on the lid
emblem_rot = 90;     // 90 = emblem reads upright when the case is turned with the ESP32 bay at the bottom
logo_svg   = "";     // path to your OWN logo/artwork (SVG) to use instead of the built-in
                     // note + NFC-waves emblem. "" = built-in emblem

// ---------------- shell ----------------
wall     = 2.0;    // outer wall
floor_t  = 1.6;    // floor thickness
lid_t    = 1.6;    // lid plate thickness (this is what the card reads through)
lid_round = 1.2;   // rounded top edge of the lid. Rounded up to 45 degrees, then a short 45 degree chamfer,
                   // so it prints cleanly with the outer face on the bed. 0 = sharp edge
r_out    = 2.0;    // outer corner radius
tol      = 0.3;    // clearance around each board
div_t    = 1.6;    // divider between the two boards
lip_t    = 1.0;    // lid lip (the part that goes inside the walls)
lip_h    = 2.0;
lip_clr  = 0.15;   // lip clearance to the walls (friction fit). Was 0.2, which was a bit loose.
// Snap fit: small bumps on the lid lip click into grooves in the base walls.
snap     = true;   // false = plain friction fit
snap_h   = 0.3;    // bump height. More = firmer click (0.2 softer, 0.4 firm)
snap_zh  = 0.6;    // flat height of a bump (it has 45 degree ramps on both sides)
snap_len = 8;      // bump length

// ---------------- PN532 V3 module ----------------
pn_w = 42.7;       // X size (listing says 4.2 cm)               (ASSUMED, measure!)
pn_d = 40.4;       // Y size (listing says 4.0 cm)               (ASSUMED, measure!)
pn_t = 1.2;        // PCB thickness
pn_hole_d     = 3.0;   // mounting holes, two opposite corners   (ASSUMED from photo)
pn_hole_inset_x = 7.0; // hole centre distance from the LEFT/RIGHT board edges  (measured by you: 7 mm)
pn_hole_inset_y = 7.0; // hole centre distance from the TOP/BOTTOM board edges  (measured by you: 7 mm)
// Looking from above with the ESP32 bay at the bottom ("south"), the holes must be top-right and
// bottom-left. In this model the ESP32 bay is on the east side, which makes that diagonal "mirrored".
pn_hole_tr_shift = 1.5; // top-right hole (ESP32 bay south): move this far to the LEFT
pn_peg_short = 0.5;   // lid pegs over the PN532 holes: this much shorter than 'touching the PCB' (lid wouldn't close)
pn_hole_mirror = true; // true = holes on the other diagonal
pn_top_h = 2.6;    // tallest part above the PCB (header, DIP switch)  (ASSUMED)
pn_gap   = 0.2;    // air between those parts and the lid

// ---------------- Seeed Studio XIAO ESP32C3 ----------------
// (was an ESP32-C3 Super Mini, 17.8 x 24 x 1.0)
c3_w = 17.8;       // Seeed: 21 x 17.8 mm (some shops list 17.5; 17.8 is the safe value)
c3_l = 21.0;
c3_t = 1.2;         // PCB thickness: users measure 1.17-1.27 mm   (ASSUMED, measure!)
c3_usb_h = 3.3;    // USB-C height above the PCB
c3_usb_w = 9.0;
c3_hdr_h = 2.5;    // header plastic under the PCB
c3_tail  = 1.0;    // how far the ESP32's pin tails stick out below the header plastic, AFTER snipping.
                   // The ESP32 cannot sit lower than its pins allow (see the echo line when you render).
c3_under_min = c3_hdr_h + c3_tail + 0.5;   // free space the pins need under the PCB
base_under = 6.0;  // original design: 2.5 + 3.0 + 0.5. The case height is measured from this.
drop     = 2.0;    // lower BOTH boards by this much, relative to the original design. The case does NOT get taller.
c3_header = false;     // true = the ESP32 has its pin header soldered on (needs room under the board)
c3_extra_drop = 2.0;   // ESP32 sits this much LOWER still than the PN532 (the cable runs over the power entry and the lid must shut)
c3_under = c3_header ? max(c3_under_min, base_under - drop - c3_extra_drop)
                     : max(1.0, base_under - drop - c3_extra_drop);   // free space under the ESP32
usb_gap  = 0.8;    // gap between PCB end and the wall at the USB end
usb_plug_h = 6.5;  // height of YOUR cable's plug (the moulded part). The lid has no cut-out for it,
                   // so this sets the headroom: the plug sits centred on the port and must fit under the lid.
usb_cut_w = 14;    // opening for the cable plug
usb_cut_h = 8;
usb_cover_h   = 4.5; // tab on the lid that hangs down into the top of the USB opening and closes the gap
                     // above the cable plug. Set it to the gap you measure above YOUR plug. 0 = no tab
usb_cover_clr = 0.2; // clearance between the tab and each side of the opening

wire_gap = 10;   // extra open room between the PN532 divider and the ESP32 for the wiring (case gets this much longer)
pad_x = 5.0;  pad_y = 1.6;   // C3 support pads at the PCB corners
stop_t = 1.5;
c3_guide_w = 1.6;  c3_guide_l = 6.0;  c3_guide_up = 1.5;   // bed guides: thickness, length, height above the PCB top
// Lid pegs that press the ESP32 down at its corners. On the XIAO the RESET and BOOT buttons sit in the two
// corners at the far end (opposite the USB-C), with the U.FL antenna connector between them.
c3_pegs_usb_end = true;    // beside the USB-C port: nothing there on the XIAO, so these stay
c3_pegs_far_end = false;   // far-end corners: OFF, they would hold RESET/BOOT pressed down
c3_peg_w = 2.8;  c3_peg_l = 2.0;   // lid hold-down pegs at the USB end of the ESP32
c3_led_x = 14.3;   // XIAO charge LED ("CH"), centre measured from the left board edge, ~0.7 mm from the USB end
                   // (scaled from Seeed's product photo). The right-hand USB-end peg stays clear of it.
c3_usb_over = 1.5; // the XIAO's USB-C sticks out this far past the board edge (from the photo). It pokes
                   // into the wall opening, which is fine: the opening starts below the PCB top.                // end stops (antenna end)

// ---------------- derived ----------------
top_orig  = floor_t + base_under + c3_t + c3_usb_h + 0.8;  // lid underside of the original design
// lid underside: the original height, or taller only if your USB plug needs it (centred on the port)
top_in    = max(top_orig, (floor_t + c3_under) + c3_t + c3_usb_h/2 + usb_plug_h/2 + 0.2);
pn_top_z  = top_orig - pn_top_h - pn_gap - drop;           // PN532 PCB top (lowered by "drop")
pn_bot_z  = pn_top_z - pn_t;                               // PN532 PCB bottom
c3_pcb_z  = floor_t + c3_under;                            // C3 PCB bottom (lowered by up to "drop")

pn_cw = pn_w + 2*tol;
pn_cd = pn_d + 2*tol;
bay_w = c3_w + 2*tol;
in_w  = pn_cw + div_t + wire_gap + bay_w;
in_d  = pn_cd;
out_w = in_w + 2*wall;
out_d = in_d + 2*wall;

c3_x0 = pn_cw + div_t + wire_gap + tol;
c3_y0 = in_d - usb_gap - c3_l;
usb_cx = c3_x0 + c3_w/2;
usb_zc = c3_pcb_z + c3_t + c3_usb_h/2;
// notch floor = PCB underside level (same height as the pads inside), unless your plug is so tall that it
// needs more room underneath (then the floor drops to the plug's underside)
usb_z0 = max(usb_zc - usb_cut_h/2, min(c3_pcb_z, usb_zc - usb_plug_h/2));

// Fine-tuning of the two PN532 posts after a test print (Nov 2026), in this file's own axes:
// +X = towards the ESP32, +Y = towards the USB wall. Seen on the dock from the front (ESP32 at the back,
// USB on the left) that is: +Y = 1 mm "to the left", -X = "towards the front/bottom".
pn_post_adj_esp   = [-0.5, 1.0];   // post nearest the ESP32: 1 mm left, 0.5 mm to the front
pn_post_adj_other = [ 0.0, 1.0];   // other post: 1 mm left
holes = pn_hole_mirror
  ? [[tol + pn_w - pn_hole_inset_x, tol + pn_hole_inset_y] + pn_post_adj_esp,
     [tol + pn_hole_inset_x,        tol + pn_d - pn_hole_inset_y - pn_hole_tr_shift] + pn_post_adj_other]
  : [[tol + pn_hole_inset_x,        tol + pn_hole_inset_y],
     [tol + pn_w - pn_hole_inset_x, tol + pn_d - pn_hole_inset_y]];
// the two corners without a hole get a plain support block
blocks = pn_hole_mirror
  ? [[0, 0], [pn_cw - 3.5, in_d - 3.5]]
  : [[0, in_d - 3.5], [pn_cw - 3.5, 0]];

win_y0 = 6;  win_y1 = in_d - 6;  win_z0 = 4;   // wire window in the divider

$fn = 48;

// lid plate with a rounded top edge (z0 = underside, h = thickness)
module lid_plate(z0, h) {
  rr = min(lid_round, h - 0.2);
  if (rr <= 0) translate([-wall, -wall, z0]) rrect(out_w, out_d, h, r_out);
  else hull() {
    translate([-wall, -wall, z0]) rrect(out_w, out_d, h - rr, r_out);
    for (a = [0 : 9 : 45]) {
      inset = rr * (1 - cos(a));
      translate([-wall + inset, -wall + inset, z0 + h - rr + rr * sin(a)])
        rrect(out_w - 2*inset, out_d - 2*inset, 0.01, max(0.1, r_out - inset));
    }
    // 45 degree chamfer from the end of the arc to the top face
    inset = rr * (1 - cos(45)) + rr * (1 - sin(45));
    translate([-wall + inset, -wall + inset, z0 + h - 0.01])
      rrect(out_w - 2*inset, out_d - 2*inset, 0.01, max(0.1, r_out - inset));
  }
}

module rrect(w, d, h, r) {
  hull() for (x = [r, w - r], y = [r, d - r]) translate([x, y, 0]) cylinder(r = r, h = h);
}

// One snap ridge: outward = +X, runs along Y, centred on the origin. Trapezoid with 45 degree ramps
// so the lid slides in and out. grow > 0 makes the matching groove a little bigger.
module ridge(len, grow) {
  h = snap_h + grow; zh = snap_zh + grow;
  rotate([90, 0, 0]) translate([0, 0, -len/2]) linear_extrude(height = len)
    polygon([[-0.4, -(zh/2 + h + 0.4)], [h, -zh/2], [h, zh/2], [-0.4, zh/2 + h + 0.4]]);
}

// Six ridges on the lip outer faces: two on the south and two on the north side (over the PN532 bay,
// away from the USB notch), one on the west and one on the east side.
module snap_at(grow, len) {
  zc = top_in - lip_h/2;
  for (x = [12, 31, pn_cw + div_t + wire_gap/2]) {
    translate([x, lip_clr, zc]) rotate([0, 0, -90]) ridge(len, grow);
    translate([x, in_d - lip_clr, zc]) rotate([0, 0, 90]) ridge(len, grow);
  }
  translate([lip_clr, in_d/2, zc]) rotate([0, 0, 180]) ridge(len, grow);
  translate([in_w - lip_clr, in_d/2, zc]) ridge(len, grow);
}

module base() {
  difference() {
    translate([-wall, -wall, 0]) rrect(out_w, out_d, top_in, r_out);
    translate([0, 0, floor_t]) cube([in_w, in_d, top_in]);
    // grooves in the wall inner faces for the lid bumps
    if (snap) snap_at(0.1, snap_len + 0.8);
    // opening for the USB cable, open at the top
    translate([usb_cx - usb_cut_w/2, in_d - 0.01, usb_z0])
      cube([usb_cut_w, wall + 0.02, top_in - usb_z0 + 0.01]);
  }
  // divider with wire window
  difference() {
    translate([pn_cw, 0, floor_t - 0.01]) cube([div_t, in_d, top_in - floor_t + 0.01]);
    translate([pn_cw - 0.1, win_y0, floor_t + win_z0]) cube([div_t + 0.2, win_y1 - win_y0, top_in]);
  }
  // PN532 posts (hole corners) with locating pins
  for (h = holes) {
    translate([h[0], h[1], floor_t - 0.01]) cylinder(d = 5.0, h = pn_bot_z - floor_t + 0.01);
    translate([h[0], h[1], pn_bot_z - 0.01]) cylinder(d = pn_hole_d - 0.8, h = 1.0);   // locating pin: 0.5 mm slimmer than before
  }
  // PN532 plain support blocks
  for (b = blocks)
    translate([b[0], b[1], floor_t - 0.01]) cube([3.5, 3.5, pn_bot_z - floor_t + 0.01]);
  // C3 corner pads
  for (sx = [0, 1], sy = [0, 1])
    translate([c3_x0 + (sx == 0 ? 0 : c3_w - pad_x), c3_y0 + (sy == 0 ? 0 : c3_l - pad_y), floor_t - 0.01])
      cube([pad_x, pad_y, c3_under + 0.01]);
  // C3 'bed': guides along the open side of the ESP32 (towards the wiring room) so it cannot slide sideways.
  // They stand beside the PCB edge at the four corners and leave the middle free for the wires.
  for (y0 = [c3_y0 - stop_t, c3_y0 + c3_l - c3_guide_l])
    translate([c3_x0 - c3_guide_w, y0, floor_t - 0.01])
      cube([c3_guide_w, c3_guide_l + (y0 < c3_y0 ? stop_t : 0), c3_under + c3_t + c3_guide_up + 0.01]);
  // C3 end stops (take the push of the USB plug)
  for (sx = [0, 1])
    translate([c3_x0 + (sx == 0 ? 0 : c3_w - pad_x), c3_y0 - stop_t, floor_t - 0.01])
      cube([pad_x, stop_t, c3_under + c3_t + 0.6]);
}

// Built-in emblem (an original design: music note + NFC waves), about 37 x 25 units,
// roughly centred on the origin.
module emblem2d() {
  translate([-6, -8]) rotate(-20) scale([1.25, 0.9]) circle(r = 5);   // note head
  translate([-1.8, -8]) square([2.4, 17]);                              // stem
  polygon([[0.6, 9], [0.6, 3.5], [10, -1], [10, 4.5]]);                // flag
  for (r = [11, 16, 21])                                                // waves
    intersection() {
      translate([4, -1]) difference() { circle(r = r); circle(r = r - 1.8); }
      translate([4, -1]) polygon([[0, 0], [60, 40], [60, -40]]);
    }
}

// the emblem, centred over the PN532 antenna (where the card is tapped).
// "raised": sits on the lid top.  "recess": a cutter that goes into the lid top.
module lid_emblem() {
  z0 = emblem_mode == "raised" ? top_in + lid_t - 0.01 : top_in + lid_t - emboss_h;
  translate([pn_cw / 2, in_d / 2, z0])
    linear_extrude(height = emboss_h + 0.01) rotate(emblem_rot) {
      if (logo_svg == "") scale(emblem_w / 37) translate([-6.4, 0.75]) emblem2d();
      else resize([emblem_w, emblem_w], auto = true) import(logo_svg, center = true);
    }
}

module lid() {
  difference() {
    union() {
      lid_plate(top_in, lid_t);
      if (emboss_h > 0 && emblem_mode == "raised") lid_emblem();
      if (snap) snap_at(0, snap_len);
      // lip
      difference() {
        translate([lip_clr, lip_clr, top_in - lip_h]) cube([in_w - 2*lip_clr, in_d - 2*lip_clr, lip_h + 0.01]);
        translate([lip_clr + lip_t, lip_clr + lip_t, top_in - lip_h - 0.1])
          cube([in_w - 2*(lip_clr + lip_t), in_d - 2*(lip_clr + lip_t), lip_h + 0.2]);
      }
      // pegs holding the PN532 down at its mounting holes
      for (h = holes)
        translate([h[0], h[1], pn_top_z + 0.1 + pn_peg_short]) cylinder(d = 4.8, h = top_in - pn_top_z - 0.1 - pn_peg_short + 0.01);
      // pegs holding the C3 down at the USB end: 2.8 mm wide, beside the port, above the corner pads
      if (c3_pegs_usb_end) {
        translate([c3_x0 + 0.2, c3_y0 + c3_l - c3_peg_l, c3_pcb_z + c3_t + 0.05])
          cube([c3_peg_w, c3_peg_l, top_in - (c3_pcb_z + c3_t + 0.05) + 0.01]);
        // right-hand peg: starts 0.9 mm past the LED centre, ends 0.2 mm from the board edge
        translate([c3_x0 + c3_led_x + 0.9, c3_y0 + c3_l - c3_peg_l, c3_pcb_z + c3_t + 0.05])
          cube([c3_w - 0.2 - (c3_led_x + 0.9), c3_peg_l, top_in - (c3_pcb_z + c3_t + 0.05) + 0.01]);
      }
      // pegs holding the C3 down at the antenna-end corners
      if (c3_pegs_far_end) for (sx = [0, 1])
        translate([c3_x0 + (sx == 0 ? 0.5 : c3_w - 3.5), c3_y0 + 0.2, c3_pcb_z + c3_t + 0.1])
          cube([3.0, 1.2, top_in - (c3_pcb_z + c3_t + 0.1) + 0.01]);
    }
    // notch in the lip only, where the plug passes; the lid plate itself stays closed (no hole)
    translate([usb_cx - usb_cut_w/2, in_d - lip_clr - lip_t - 0.1, top_in - lip_h - 0.2])
      cube([usb_cut_w, lip_t + 0.3, lip_h + 0.2]);
    // engraved emblem
    if (emboss_h > 0 && emblem_mode == "recess") lid_emblem();
    // the divider runs up to the lid, so the lip needs notches where it crosses it
    translate([pn_cw - 0.3, -1, top_in - lip_h - 0.2])
      cube([div_t + 0.6, in_d + 2, lip_h + 0.2]);
  }
  usb_cover();
}

// Tab under the lid edge, in the plane of the base wall: fills the top usb_cover_h of the USB opening.
// Outer face flush with the wall. Points up when the lid is printed outer face down (no supports).
module usb_cover() {
  if (usb_cover_h > 0)
    translate([usb_cx - usb_cut_w/2 + usb_cover_clr, in_d, top_in - usb_cover_h])
      cube([usb_cut_w - 2*usb_cover_clr, wall, usb_cover_h + 0.01]);
}

// Footprint of the USB opening, extended "ext" mm outwards, as a tall block (base() coordinates).
// Used by the dock to keep its fillet out of the way of the cable plug.
module usb_keepout(ext) {
  translate([usb_cx - usb_cut_w/2, in_d - 0.01, -50]) cube([usb_cut_w, wall + ext, 100]);
}

module boards() {
  // PN532 PCB (with its mounting holes) + conservative envelope of the parts on top,
  // keeping the mounting-hole rings free
  difference() {
    translate([tol, tol, pn_bot_z]) cube([pn_w, pn_d, pn_t]);
    for (h = holes) translate([h[0], h[1], pn_bot_z - 1]) cylinder(d = pn_hole_d, h = pn_t + 2);
  }
  difference() {
    translate([tol + 2, tol + 2, pn_top_z]) cube([pn_w - 4, pn_d - 4, pn_top_h]);
    for (h = holes) translate([h[0], h[1], pn_top_z - 1]) cylinder(d = 6, h = pn_top_h + 2);
  }
  // C3 PCB, USB-C, headers + tails below
  translate([c3_x0, c3_y0, c3_pcb_z]) cube([c3_w, c3_l, c3_t]);
  translate([usb_cx - c3_usb_w/2, c3_y0 + c3_l - 7.4, c3_pcb_z + c3_t])
    cube([c3_usb_w, 7.4 + c3_usb_over, c3_usb_h]);
  if (c3_header)
    for (sx = [0, c3_w - 2.54])
      translate([c3_x0 + sx, c3_y0 + 1.84, c3_pcb_z - c3_hdr_h - c3_tail])
        cube([2.54, c3_l - 3.68, c3_hdr_h + c3_tail]);
}

if (part == "base") base();
else if (part == "lid") lid();
// lid flipped for printing: outer face on the bed, lip and pegs pointing up (no supports)
else if (part == "lid_print") translate([0, out_d - wall, top_in + lid_t]) rotate([180, 0, 0]) lid();
else if (part == "boards") boards();
else { base(); lid(); boards(); }

echo(str("ESP32 top of USB-C at z=", c3_pcb_z + c3_t + c3_usb_h, "; lid USB tab bottom at z=", top_in - usb_cover_h, "; free space above the PCB: ", top_in - c3_pcb_z - c3_t));
echo(str("outer size: ", out_w, " x ", out_d, " x ", top_in + lid_t));
echo(str("USB opening: from z=", usb_z0, " to ", top_in, "; lid tab covers the top ", usb_cover_h, " mm, leaving ", top_in - usb_cover_h - usb_z0, " mm for the plug"));
echo(str("PN532 post height: ", pn_bot_z - floor_t, "  (PN532 lowered ", drop, " mm)"));
echo(str("ESP32 header: ", c3_header, "  extra drop: ", c3_extra_drop));
echo(str("ESP32 lowered ", base_under - c3_under, " mm; free space under it: ", c3_under, " mm; pad height: ", c3_under));
if (c3_header && base_under - c3_under < drop + c3_extra_drop - 0.001)
  echo(str("NOTE: the ESP32 can only be lowered ", base_under - c3_under, " mm, not ", drop,
           " mm, because its pin tails (c3_tail = ", c3_tail, " mm) need the room. Snip them shorter to go lower."));
