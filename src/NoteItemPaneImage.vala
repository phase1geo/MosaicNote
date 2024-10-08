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

  private Label   _h2_label;
  private Picture _image;

  public NoteItemImage image_item {
    get {
      return( (NoteItemImage)item );
    }
  }

	// Default constructor
	public NoteItemPaneImage( MainWindow win, NoteItem item, SpellChecker? spell ) {
    base( win, item, spell );
  }

  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    _image.grab_focus();
  }

  // Displays a dialog to request
  private void image_dialog( NoteItemImage item ) {

    var dialog = Utils.make_file_chooser( _( "Select Image" ), _( "Select" ) );

    dialog.open.begin( win, null, (obj, res) => {
      try {
        var file = dialog.open.end( res );
        if( file != null ) {
          if( file.get_uri() != item.uri ) {
            win.undo.add_item( new UndoItemImageChange( image_item ) );
            item.uri = file.get_uri();
          }
        }
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Create custom header when the pane is selected.
  protected override Widget create_header1() {

    var default_text = _( "Description (Optional)" );

    var entry = new EditableLabel( (image_item.description == "") ? default_text : image_item.description ) {
      halign = Align.FILL,
      hexpand = true
    };

    entry.notify["editing"].connect(() => {
      if( !entry.editing ) {
        var text = (entry.text == default_text) ? "" : entry.text;
        if( image_item.description != text ) {
          win.undo.add_item( new UndoItemDescChange( item, image_item.description ) );
          image_item.description = text;
          _h2_label.label = Utils.make_title( text );
        }
      }
    });

    var open = new Button.from_icon_name( "image-x-generic-symbolic" ) {
      halign       = Align.END,
      has_frame    = false,
      tooltip_text = _( "Change Image" )
    };

    open.clicked.connect(() => {
      image_dialog( image_item );
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );
    box.append( open );

    save.connect(() => {
      var text = (entry.text == default_text) ? "" : entry.text;
      if( image_item.description != text ) {
        win.undo.add_item( new UndoItemDescChange( item, image_item.description ) );
        image_item.description = text;
        _h2_label.label = Utils.make_title( text );
      }
    });

    image_item.notify["description"].connect(() => {
      var text = (image_item.description == "") ? default_text : image_item.description;
      if( entry.text != text ) {
        entry.text = text;
        _h2_label.label = Utils.make_title( text );
      }
    });

    return( box );

  }

  //-------------------------------------------------------------
  // Create custom header when the pane is not selected.
  protected override Widget? create_header2() {

    _h2_label = new Label( Utils.make_title( image_item.description ) ) {
      use_markup = true,
      halign = Align.FILL,
      justify = Justification.CENTER
    };

    return( _h2_label );

  }

  //-------------------------------------------------------------
  // Adds the UI for the image panel.
  protected override Widget create_pane() {

    var image_item  = (NoteItemImage)item;
    var image_click = new GestureClick();
    var image_focus = new EventControllerFocus();
    var image_drag  = new DragSource() {
      actions = Gdk.DragAction.COPY
    };
    var image_drop  = new DropTarget( typeof(GLib.File), Gdk.DragAction.COPY );

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
    _image.add_controller( image_drag );
    _image.add_controller( image_drop );

    if( image_item.uri == "" ) {
      image_dialog( image_item );
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
        show_image();
      }
    });

    image_focus.enter.connect(() => {
      set_as_current();
    });

    image_drag.prepare.connect((d) => {
      var val = Value( typeof(GLib.File) );
      val = _image.file;
      var cp = new Gdk.ContentProvider.for_value( val );
      return( cp );
    });

    image_drop.drop.connect((val, x, y) => {
      var file = (val as GLib.File);
      if( file != null ) {
        uint8[] contents = {};
        try {
          if( file.load_contents( null, out contents, null ) && GLib.ContentType.guess( null, contents, null ).contains( "image" ) ) {
            if( image_item.uri != file.get_uri() ) {
              win.undo.add_item( new UndoItemImageChange( image_item ) );
              image_item.uri = file.get_uri();
            }
            return( true );
          }
        } catch( Error e ) {}
      }
      return( false );
    });

    image_item.notify["uri"].connect(() => {
      _image.file = File.new_for_path( image_item.get_resource_filename() );
    });

    handle_key_events( _image );

    return( box );

  }

  //-------------------------------------------------------------
  // Overrides the copy to clipboard functionality.
  protected override void copy_to_clipboard( Gdk.Clipboard clipboard ) {
    try {
      var texture = Gdk.Texture.from_filename( image_item.get_resource_filename() );
      clipboard.set_texture( texture );
    } catch( Error e ) {}
  }

}