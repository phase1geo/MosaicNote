/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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

public enum ImageZoomLevel {
  ZOOM_100,
  ZOOM_125,
  ZOOM_150,
  ZOOM_175,
  ZOOM_200,
  ZOOM_400,
  ZOOM_800,
  NUM;

  //-------------------------------------------------------------
  // Returns the zoom factor multiplier for each zoom setting.
  public double zoom_factor() {
    switch( this ) {
      case ZOOM_100 :  return( 1.0 );
      case ZOOM_125 :  return( 1.25 );
      case ZOOM_150 :  return( 1.5 );
      case ZOOM_175 :  return( 1.75 );
      case ZOOM_200 :  return( 2.0 );
      case ZOOM_400 :  return( 4.0 );
      case ZOOM_800 :  return( 8.0 );
      default       :  assert_not_reached();
    }
  }
}

public class ImageView : Box {

  private MainWindow       _win;
  private Array<NoteItem>? _items = null;
  private int              _current;
  private Button           _prev;
  private Button           _next;
  private Picture          _image;
  private ScrolledWindow   _sw;
  private Button           _zoom_in;
  private Button           _zoom_out;
  private ImageZoomLevel   _zoom_level = ImageZoomLevel.ZOOM_100;

  public signal void viewer_closed();

  //-------------------------------------------------------------
  // Default constructor
  public ImageView( MainWindow win ) {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5,
      halign: Align.FILL,
      valign: Align.FILL,
      margin_start: 5,
      margin_end: 5,
      margin_top: 5,
      margin_bottom: 5
    );

    _win = win;

    var header = create_header();    

    _image = new Picture() {
      hexpand = true,
      vexpand = true
    };

    _sw = new ScrolledWindow() {
      has_frame         = true,
      hscrollbar_policy = PolicyType.AUTOMATIC,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      halign            = Align.FILL,
      valign            = Align.FILL,
      child             = _image
    };

    append( header );
    append( _sw );

  }

  //-------------------------------------------------------------
  // Creates the header bar within this viewer
  private Widget create_header() {

    _prev = new Button.from_icon_name( "pan-start-symbolic" ) {
      has_frame = false,
      tooltip_text = _( "View Previous Image" )
    };

    _prev.clicked.connect(() => {
      if( _current > 0 ) {
        _current--;
        show_current_image();
      }
    });

    _next = new Button.from_icon_name( "pan-end-symbolic" ) {
      has_frame = false,
      tooltip_text = _( "View Next Image" )
    };

    _next.clicked.connect(() => {
      if( (_current + 1) < _items.length ) {
        _current++;
        show_current_image();
      }
    });

    var navbox = new Box( Orientation.HORIZONTAL, 0 ) {
      halign  = Align.START,
      hexpand = true
    };
    navbox.append( _prev );
    navbox.append( _next );

    _zoom_in = new Button.from_icon_name( "zoom-in-symbolic" ) {
      halign = Align.END,
      has_frame = false,
      tooltip_text = _( "Zoom In" )
    };

    _zoom_in.clicked.connect(() => {
      if( ((int)_zoom_level + 1) < ImageZoomLevel.NUM ) {
        set_zoom_level( (int)_zoom_level + 1 );
      }
    });

    _zoom_out = new Button.from_icon_name( "zoom-out-symbolic" ) {
      halign = Align.END,
      has_frame = false,
      tooltip_text = _( "Zoom Out" )
    };

    _zoom_out.clicked.connect(() => {
      if( ((int)_zoom_level - 1) > 0 ) {
        set_zoom_level( (int)_zoom_level - 1 );
      }
    });

    var close = new Button.from_icon_name( "window-close-symbolic" ) {
      has_frame = false,
      halign = Align.END,
      tooltip_text = _( "Close Image Viewer" )
    };

    close.clicked.connect(() => {
      viewer_closed();
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( navbox );
    box.append( _zoom_in );
    box.append( _zoom_out );
    box.append( close );

    return( box );

  }

  //-------------------------------------------------------------
  // Should be used to set the zoom level to the required setting.
  private void set_zoom_level( ImageZoomLevel zoom_level ) {
    _zoom_level = zoom_level;
    _zoom_in.sensitive  = ((int)_zoom_level + 1) != ImageZoomLevel.NUM;
    _zoom_out.sensitive = ((int)_zoom_level != 0);
    zoom_image();
  }

  //-------------------------------------------------------------
  // Zooms the image to the current zoom level.
  private void zoom_image() {
    var factor = _zoom_level.zoom_factor();
    var width  = (int)(_sw.get_allocated_width()  * factor);
    var height = (int)(_sw.get_allocated_height() * factor);
    var hval   = _sw.hadjustment.value;
    var vval   = _sw.vadjustment.value;
    _image.set_size_request( width, height );
    Idle.add(() => {
      _sw.hadjustment.value = hval;
      _sw.vadjustment.value = vval;
      return( false );
    });
  }

  //-------------------------------------------------------------
  // Displays the current image.
  private void show_current_image() {

    set_zoom_level( ImageZoomLevel.ZOOM_100 );

    _image.file = File.new_for_path( _items.index( _current ).get_resource_filename() );

    _prev.sensitive = (_current != 0);
    _next.sensitive = ((_current + 1) != _items.length);

  }

  //-------------------------------------------------------------
  // Populates the image viewer with a list of images to display.
  public void populate( Array<NoteItem> items, int current ) {
    _items   = items;
    _current = current;
    show_current_image();
  }

}