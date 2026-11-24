/*
  Card crate for NFC album cards (holds n_cards, standing upright like records).
  Open top, one piece, prints floor-down with no supports.
  Front wall is low so you see the artwork; back wall is tall to support the cards.
  Units: mm.   openscad -o card-box.stl nfc-card-box.scad

  show_logo: false = no logo on the front (only the text). Set true to engrave a logo.
  logo_svg: path to your OWN logo/artwork (SVG) to engrave instead of the
  built-in note + NFC-waves emblem. Leave "" to use the emblem. Only used when show_logo = true.
  text_str: set to "" for a completely plain front.
*/

n_cards  = 50;
card_t   = 0.9;      // card + label thickness (PVC card ~0.76-0.84 + label ~0.1)  (ASSUMED, measure a stack of 10)
slack    = 6;        // spare room so the stack is not jammed
card_w   = 54.0;
card_h   = 86.0;
clr      = 0.6;      // side clearance

wall     = 2.0;
floor_t  = 2.0;
r_out    = 2.5;
h_back   = 64;       // back wall height above the table (before the top cut, see cut_h)
h_front  = 40;       // front wall height
cut_h    = 54;       // flat cut: everything above this height is removed, like stopping the print here.
                     // The slope runs up from the front and levels off at this height. 0 = no cut
cut_round = 40;      // radius of the rounded transition between the slope and the flat top. 0 = sharp kink

show_logo  = false;
logo_svg   = "";
logo_depth = 0.8;
text_str   = "";         // "" = no text on the front. Put e.g. "ALBUMS" back to engrave it

in_w = card_w + 2*clr;
box_depth = 77.3;   // outer depth front-to-back. 77.3 = same length as the reader case, so both line up
                    // in the dock. 0 = size it from n_cards * card_t + slack instead.
in_d = box_depth > 0 ? box_depth - 2*wall : n_cards*card_t + slack;
out_w = in_w + 2*wall;
out_d = in_d + 2*wall;
$fn = 48;

module rrect2(w, d, r) {
  hull() for (x = [r, w - r], y = [r, d - r]) translate([x, y]) circle(r = r);
}

// side profile in the Y-Z plane (Y = depth, front at y=0): sloped top from front to back
module profile() {
  if (cut_h <= 0 || cut_h >= h_back) polygon([[0, 0], [out_d, 0], [out_d, h_back], [0, h_front]]);
  else {
    th = atan((h_back - h_front) / out_d);           // slope angle
    yk = (cut_h - h_front) / tan(th);                // where the slope reaches cut_h
    t  = cut_round * tan(th / 2);                    // tangent length of the rounding
    c  = [yk + t, cut_h - cut_round];                // centre of the rounding arc
    arc = cut_round > 0
      ? [for (a = [90 + th : -th / 24 : 90]) c + cut_round * [cos(a), sin(a)]]
      : [[yk, cut_h]];
    polygon(concat([[0, 0], [out_d, 0], [out_d, cut_h]], [for (i = [len(arc) - 1 : -1 : 0]) arc[i]], [[0, h_front]]));
  }
}

// 2D emblem in X-Z coordinates, centred at 0,0, about 30 mm square: note + radiating waves
module emblem() {
  // note head, stem and flag
  translate([-6, -8]) rotate(-20) scale([1.25, 0.9]) circle(r = 5);
  translate([-1.8, -8]) square([2.4, 17]);
  polygon([[0.6, 9], [0.6, 3.5], [10, -1], [10, 4.5]]);
  // waves
  for (r = [11, 16, 21])
    intersection() {
      translate([4, -1]) difference() { circle(r = r); circle(r = r - 1.8); }
      translate([4, -1]) polygon([[0, 0], [60, 40], [60, -40]]);
    }
}

module engraving() {
  // lies on the front face (y = 0), facing -Y
  if (show_logo)
    rotate([90, 0, 0]) translate([out_w/2, 23, 0]) linear_extrude(height = logo_depth * 2, center = true) {
      if (logo_svg == "") {
        scale(0.8) translate([-5.5, 0]) emblem();
      } else {
        resize([26, 26], auto = true) import(logo_svg, center = true);
      }
    }
  if (text_str != "")
    rotate([90, 0, 0]) translate([out_w/2, 6.5, 0]) linear_extrude(height = logo_depth * 2, center = true)
      text(text_str, size = 5, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
}

module box() {
  difference() {
    // outer shell: extruded side profile, rounded vertical corners via intersection
    intersection() {
      translate([0, out_d, 0]) rotate([90, 0, 0]) mirror([0, 0, 0])
        rotate([0, 0, 0]) translate([0, 0, 0]) linear_extrude(height = out_d) square([out_w, h_back]);
      // the profile, extruded along X
      translate([0, 0, 0]) rotate([90, 0, 90]) linear_extrude(height = out_w) profile();
      linear_extrude(height = h_back) rrect2(out_w, out_d, r_out);
    }
    // card cavity, open on top, cut to follow the same slope so the side walls keep their thickness
    translate([wall, wall, floor_t]) cube([in_w, in_d, h_back]);
    // thumb scoop in the front wall top so the first card is easy to grab
    translate([out_w/2, -1, h_front + 14]) rotate([-90, 0, 0]) cylinder(r = 17, h = wall + 2);
    engraving();
  }
}

box();
echo(str("outer: ", out_w, " x ", out_d, " x ", h_back, "  inner depth for cards: ", in_d, " (about ", floor(in_d / card_t), " cards packed tight)"));
