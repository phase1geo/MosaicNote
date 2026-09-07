/*
* Copyright (c) 2026 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;
using Pango;

public class AutoFitLabel : Box {

  private Label _label;
  private bool  _adjusting = false;

  public string label {
    get {
      return( _label.label );
    }
    set {
      _label.label = value;
    }
  }
  public double min_font_size { get; set; default = 8.0; }
  public double max_font_size { get; set; default = 100.0; }

  //-------------------------------------------------------------
  // Space to leave around the text, in pixels.
  public int padding { get; set; default = 0; }

  //-------------------------------------------------------------
  // Constructor
  public AutoFitLabel( string? text = null ) {
    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _label = new Label( text ?? "" ) {
      use_markup = true,
      xalign = 0.0f,
      yalign = 0.0f,
      justify = Justification.CENTER,
      wrap = true
    };

    // Width/height changes cause us to recalculate the font size.
    _label.notify["width"].connect(() => {
      adjust_font_size();
    });

    _label.notify["height"].connect(() => {
      adjust_font_size();
    });

    _label.notify["label"].connect(() => {
      adjust_font_size();
    });

    append( _label );

  }

  protected override void size_allocate( int width, int height, int baseline ) {
    base.size_allocate( width, height, baseline );
    adjust_font_size();
  }

  private void adjust_font_size() {

    if( _adjusting ) {
      return;
    }

    var width  = _label.get_width()  - padding * 2;
    var height = _label.get_height() - padding * 2;

    if( (width <= 0) || (height <= 0) ) {
      return;
    }

    var text = _label.get_label();

    if( (text == null) || (text.length == 0) ) {
      return;
    }

    _adjusting = true;

    // Start with the font that GTK is currently using.
    var context   = _label.get_pango_context();
    var base_font = context.get_font_description().copy();

    // Binary search for the largest font size that fits.
    var low  = min_font_size;
    var high = max_font_size;
    var best = min_font_size;

    for( int i=0; i<10; i++ ) {

      var size = (low + high) / 2.0;

      base_font.set_size( (int)(size * Pango.SCALE) );

      var layout = create_pango_layout( null );
      try {
        layout.set_markup( text, -1 );
      } catch ( Error e ) {
        layout.set_text( text, -1 );   // fallback if markup is invalid
      }

      layout.set_font_description( base_font );
      layout.set_width( width * Pango.SCALE );
      layout.set_wrap( Pango.WrapMode.WORD_CHAR );

      int text_width;
      int text_height;

      layout.get_pixel_size( out text_width, out text_height );

      if( (text_width <= width) && (text_height <= height) ) {
        best = size;
        low = size;
      } else {
        high = size;
      }

    }

    var attributes = new Pango.AttrList();
    attributes.insert( new Pango.AttrSize( (int)(best * Pango.SCALE) ) );
    _label.set_attributes( attributes );

    _adjusting = false;

  }

}
