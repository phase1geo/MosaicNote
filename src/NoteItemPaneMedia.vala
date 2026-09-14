/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

public class NoteItemPaneMedia : NoteItemPane {

  private ulong _description_id = 0;

  private Label          _h2_label;
  private Picture        _display;
  private MediaControls? _controls = null;

  public NoteItemMedia media_item {
    get {
      return( (NoteItemMedia)item );
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneMedia( MainWindow win, NoteItem item, SpellChecker? spell ) {
    base( win, item, spell );
  }

  //-------------------------------------------------------------
  // Destructor
  ~NoteItemPaneMedia() {
    if( MosaicNote.debug ) {
      stdout.printf( "NoteItemPaneMedia destroyed\n" );
    }
  }

  //-------------------------------------------------------------
  // Removes all signal connections prior to destruction.
  public override void cleanup() {
    base.cleanup();
  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement, int offset = 0 ) {
    _display.grab_focus();
  }

  //-------------------------------------------------------------
  // Displays a dialog to request
  private void media_dialog( NoteItemMedia item ) {

    var dialog = Utils.make_file_chooser( _( "Select Audio/Video File" ), _( "Select" ) );

    dialog.open.begin( win, null, (obj, res) => {
      try {
        var file = dialog.open.end( res );
        if( file != null ) {
          if( file.get_uri() != item.uri ) {
            win.undo.add_item( new UndoItemMediaChange( media_item ) );
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

    var entry = new EditableLabel( (media_item.description == "") ? default_text : media_item.description ) {
      halign = Align.FILL,
      hexpand = true
    };

    var editing_id = entry.notify["editing"].connect(() => {
      if( !entry.editing ) {
        var text = (entry.text == default_text) ? "" : entry.text;
        if( media_item.description != text ) {
          win.undo.add_item( new UndoItemDescChange( item, media_item.description ) );
          media_item.description = text;
          _h2_label.label = Utils.make_title( text );
        }
      }
    });
    add_signal( entry, editing_id );

    var open = new Button.from_icon_name( "document-open-symbolic" ) {
      halign       = Align.END,
      has_frame    = false,
      tooltip_text = _( "Open Audio/Video File" )
    };

    var open_id = open.clicked.connect(() => {
      media_dialog( media_item );
    });
    add_signal( open, open_id );

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );
    box.append( open );

    var save_id = save.connect(() => {
      var text = (entry.text == default_text) ? "" : entry.text;
      if( media_item.description != text ) {
        win.undo.add_item( new UndoItemDescChange( item, media_item.description ) );
        media_item.description = text;
        _h2_label.label = Utils.make_title( text );
      }
    });
    add_signal( this, save_id );

    var description_id = media_item.notify["description"].connect(() => {
      var text = (media_item.description == "") ? default_text : media_item.description;
      if( entry.text != text ) {
        entry.text = text;
        _h2_label.label = Utils.make_title( text );
      }
    });
    add_signal( media_item, description_id );

    return( box );

  }

  //-------------------------------------------------------------
  // Returns true if a valid header2 exists.
  protected override bool header2_exists() {
    return( media_item.description.chomp() != "" );
  }

  //-------------------------------------------------------------
  // Create custom header when the pane is not selected.
  protected override Widget? create_header2() {

    _h2_label = new Label( Utils.make_title( media_item.description ) ) {
      use_markup = true,
      halign = Align.FILL,
      justify = Justification.CENTER
    };

    return( _h2_label );

  }

  //-------------------------------------------------------------
  // Updates the media elements whenever we have media to display.
  private void update_media() {

    var fname = media_item.get_resource_filename();
    var file  = File.new_for_path( fname );
    var media = MediaFile.for_file( file );

    if( !media.prepared ) {
      ulong prepared_id = 0;
      prepared_id = media.notify["prepared"].connect(() => {
        _display.set_paintable( media );
        _controls.media_stream = media;
        _display.visible  = media.has_video;
        _controls.visible = media.has_audio;
        media.disconnect( prepared_id );
      });
    }

  }

  //-------------------------------------------------------------
  // Adds the UI for the image panel.
  protected override Widget create_pane() {

    var media_item  = (NoteItemMedia)item;
    var media_focus = new EventControllerFocus();

    _display = new Picture() {
      halign = Align.FILL,
      valign = Align.FILL,
      hexpand = true,
      vexpand = true,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    _display.set_size_request( 600, 400 );
    _display.add_controller( media_focus );

    _controls = new MediaControls( null ) {
      halign = Align.FILL,
      visible = false
    };

    if( media_item.uri == "" ) {
      // image_dialog( image_item );
      // TODO - We will want to display the screen to allow us to select an image or take a screenshot
    } else {
      update_media();
    }

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( _display );
    box.append( _controls );

    var enter_id = media_focus.enter.connect(() => {
      set_as_current( true );
    });
    add_signal( media_focus, enter_id );

    /*
    var drag_prepare_id = image_drag.prepare.connect((d) => {
      var val = Value( typeof(GLib.File) );
      val = _image.file;
      var cp = new Gdk.ContentProvider.for_value( val );
      return( cp );
    });
    add_signal( image_drag, drag_prepare_id );

    var drop_drop_id = image_drop.drop.connect((val, x, y) => {
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
    add_signal( image_drop, drop_drop_id );
    */

    var uri_id = media_item.notify["uri"].connect(() => {
      update_media();
    });
    add_signal( media_item, uri_id );

    handle_key_events( _display );

    return( box );

  }

  //-------------------------------------------------------------
  // Performs note search over this item.
  public override void do_search( NoteSearchFunc command ) {
    command( this, "desc", media_item.description, _h2_label );
  }

  //-------------------------------------------------------------
  // Called when the pane is cleared as the current pane.
  public override void clear_current() {
    base.clear_current();
    _controls.visible = _controls.media_stream.has_audio;
  }

  /*
  //-------------------------------------------------------------
  // Overrides the copy to clipboard functionality.
  protected override void copy_to_clipboard( Gdk.Clipboard clipboard ) {
    try {
      var texture = Gdk.Texture.from_filename( image_item.get_resource_filename() );
      clipboard.set_texture( texture );
    } catch( Error e ) {}
  }
  */

}
