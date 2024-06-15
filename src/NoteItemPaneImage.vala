/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
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

public class NoteItemPaneImage : NoteItemPane {

  private Picture _image;

	// Default constructor
	public NoteItemPaneImage( MainWindow win, NoteItem item, SpellChecker spell ) {
    base( win, item, spell );
  }

  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    _image.grab_focus();
  }

  // Displays a dialog to request
  private void image_dialog( NoteItemImage item, Picture image ) {

    var dialog = Utils.make_file_chooser( _( "Select Image" ), win, FileChooserAction.OPEN, _( "Select" ) );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var file = dialog.get_file();
        if( file != null ) {
          item.uri = file.get_uri();
          image.file = file;
        }
      }
      dialog.destroy();
    });

    dialog.show();

  }

  protected override Widget create_pane() {

    var image_item  = (NoteItemImage)item;
    var image_click = new GestureClick();
    var image_focus = new EventControllerFocus();
    _image = new Picture() {
      halign = Align.FILL,
      valign = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      focusable     = true
    };
    _image.add_controller( image_click );
    _image.add_controller( image_focus );

    if( image_item.uri == "" ) {
      image_dialog( image_item, _image );
    } else {
      _image.file = File.new_for_path( image_item.get_resource_filename() );
    }

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( _image );
    box.set_size_request( -1, 500 );
    box.add_css_class( "themed" );

    image_click.pressed.connect((n_press, x, y) => {
      if( n_press == 1 ) {
        _image.grab_focus();
      } else if( n_press == 2 ) {
        image_dialog( image_item, _image );
      }
    });

    image_focus.enter.connect(() => {
      set_as_current();
    });

    handle_key_events( _image );

    return( box );

  }

}