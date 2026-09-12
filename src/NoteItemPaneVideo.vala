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

public class NoteItemPaneVideo : NoteItemPane {

  private ulong _description_id = 0;

  private Label         _h2_label;
  private Video         _video;
  private NoteItemImage _temp_item;

  public NoteItemVideo video_item {
    get {
      return( (NoteItemVideo)item );
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneVideo( MainWindow win, NoteItem item, SpellChecker? spell ) {
    base( win, item, spell );
  }

  //-------------------------------------------------------------
  // Destructor
  ~NoteItemPaneVideo() {
    if( MosaicNote.debug ) {
      stdout.printf( "NoteItemPaneVideo destroyed\n" );
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
    _video.grab_focus();
  }

  //-------------------------------------------------------------
  // Displays a dialog to request
  private void video_dialog( NoteItemVideo item ) {

    var dialog = Utils.make_file_chooser( _( "Select Video" ), _( "Select" ) );

    dialog.open.begin( win, null, (obj, res) => {
      try {
        var file = dialog.open.end( res );
        if( file != null ) {
          stdout.printf( "file: %s\n", file.get_uri() );
          if( file.get_uri() != item.uri ) {
            stdout.printf( "  HERE!\n" );
            win.undo.add_item( new UndoItemVideoChange( video_item ) );
            stdout.printf( "  Setting item to %s\n", file.get_uri() );
            item.uri = file.get_uri();
          }
        }
      } catch( Error e ) {}
    });

  }

  /*
  //-------------------------------------------------------------
  // Displays screenshot utility to request
  private void do_screenshot( NoteItemImage item ) {
    _temp_item = item;
    do_screenshot_portal.begin();
  }

  //-------------------------------------------------------------
  // Waits for the given number of milliseconds.
  private async void screenshot_wait_ms( uint ms ) {
    GLib.Timeout.add( ms, () => {
      screenshot_wait_ms.callback();
      return Source.REMOVE;
    });
    yield;
  }

  //-------------------------------------------------------------
  // Perform the screenshot.
  private async void do_screenshot_portal() {

    DBusConnection? bus = null;
    uint subscribe_id = 0;

    // We will hide the MosaicNote window to capture the screenshot
    win.hide();
    yield screenshot_wait_ms( 200 );

    try {

      bus = Bus.get_sync( BusType.SESSION );

      var proxy = new DBusProxy.sync(
        bus,
        DBusProxyFlags.NONE,
        null,
        "org.freedesktop.portal.Desktop",
        "/org/freedesktop/portal/desktop",
        "org.freedesktop.portal.Screenshot",
        null
      );

      // Predict the Request handle so we can subscribe to its Response
      // signal BEFORE issuing the Screenshot call.  Subscribing after
      // the call returns races against the portal: when the helper is
      // already running and responds quickly (typical for the second
      // and subsequent screenshots in a session) the Response can fire
      // before signal_subscribe is wired up, dropping the screenshot.
      // The handle path format is defined by the XDG portal spec.
      var token  = "mosaic_note_%u".printf( Random.next_int() );
      var sender = bus.get_unique_name().substring( 1 ).replace( ".", "_" );
      var handle = "/org/freedesktop/portal/desktop/request/%s/%s".printf( sender, token );

      subscribe_id = bus.signal_subscribe(
        "org.freedesktop.portal.Desktop",
        "org.freedesktop.portal.Request",
        "Response",
        handle,
        null,
        DBusSignalFlags.NONE,
        (connection, sender_name, object_path, interface_name, signal_name, parameters) => {
          connection.signal_unsubscribe( subscribe_id );
          handle_screenshot_callback( connection, sender_name, object_path, interface_name, signal_name, parameters );
        }
      );

      VariantDict options = new VariantDict( new Variant( "a{sv}" ) );
      options.insert_value( "interactive",  new Variant.boolean( true ) );
      options.insert_value( "handle_token", new Variant.string( token ) );

      Variant dict_variant  = options.end ();
      Variant tuple_variant = new Variant( "(s@a{sv})", "interactive", dict_variant );

      yield proxy.call(
        "Screenshot",
        tuple_variant,
        DBusCallFlags.NONE,
        -1,
        null
      );

    } catch (Error e) {
      if( (bus != null) && (subscribe_id != 0) ) {
        bus.signal_unsubscribe( subscribe_id );
      }
      warning ("Screenshot failed: %s", e.message);
      win.show();
    }

  }

  //-------------------------------------------------------------
  // Handle the screenshot callback and update the UI.
  private void handle_screenshot_callback(
    DBusConnection connection,
    string? sender_name,
    string object_path,
    string interface_name,
    string signal_name,
    Variant parameters
  ) {

    uint response;
    Variant dict;
    string uri = "";

    parameters.get( "(u@a{sv})", out response, out dict );

    if( (response == 0) && dict.lookup( "uri", "s", out uri ) ) {
      var file = File.new_for_uri( uri );
      if( file != null ) {
        if( file.get_uri() != _temp_item.uri ) {
          win.undo.add_item( new UndoItemImageChange( image_item ) );
          _temp_item.uri = file.get_uri();
        }
      }
    }

    win.show();

  }
  */

  //-------------------------------------------------------------
  // Create custom header when the pane is selected.
  protected override Widget create_header1() {

    var default_text = _( "Description (Optional)" );

    var entry = new EditableLabel( (video_item.description == "") ? default_text : video_item.description ) {
      halign = Align.FILL,
      hexpand = true
    };

    var editing_id = entry.notify["editing"].connect(() => {
      if( !entry.editing ) {
        var text = (entry.text == default_text) ? "" : entry.text;
        if( video_item.description != text ) {
          win.undo.add_item( new UndoItemDescChange( item, video_item.description ) );
          video_item.description = text;
          _h2_label.label = Utils.make_title( text );
        }
      }
    });
    add_signal( entry, editing_id );

    var open = new Button.from_icon_name( "document-open-symbolic" ) {
      halign       = Align.END,
      has_frame    = false,
      tooltip_text = _( "Change Video From File" )
    };

    var open_id = open.clicked.connect(() => {
      video_dialog( video_item );
    });
    add_signal( open, open_id );

    /*
    var screenshot = new Button.from_icon_name( "insert-image" ) {
      halign = Align.END,
      has_frame = false,
      tooltip_text = _( "Change Image From Screenshot" )
    };

    var screenshot_id = screenshot.clicked.connect(() => {
      do_screenshot( image_item );
    });
    add_signal( screenshot, screenshot_id );
    */

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );
    box.append( open );
    // box.append( screenshot );

    var save_id = save.connect(() => {
      var text = (entry.text == default_text) ? "" : entry.text;
      if( video_item.description != text ) {
        win.undo.add_item( new UndoItemDescChange( item, video_item.description ) );
        video_item.description = text;
        _h2_label.label = Utils.make_title( text );
      }
    });
    add_signal( this, save_id );

    var description_id = video_item.notify["description"].connect(() => {
      var text = (video_item.description == "") ? default_text : video_item.description;
      if( entry.text != text ) {
        entry.text = text;
        _h2_label.label = Utils.make_title( text );
      }
    });
    add_signal( video_item, description_id );

    return( box );

  }

  //-------------------------------------------------------------
  // Returns true if a valid header2 exists.
  protected override bool header2_exists() {
    return( video_item.description.chomp() != "" );
  }

  //-------------------------------------------------------------
  // Create custom header when the pane is not selected.
  protected override Widget? create_header2() {

    _h2_label = new Label( Utils.make_title( video_item.description ) ) {
      use_markup = true,
      halign = Align.FILL,
      justify = Justification.CENTER
    };

    return( _h2_label );

  }

  //-------------------------------------------------------------
  // Adds the UI for the image panel.
  protected override Widget create_pane() {

    var video_item  = (NoteItemVideo)item;
    var video_focus = new EventControllerFocus();

    _video = new Video() {
      halign = Align.FILL,
      valign = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      focusable     = true,
      loop          = false,
      autoplay      = false
    };
    _video.add_controller( video_focus );

    if( video_item.uri == "" ) {
      // image_dialog( image_item );
      // TODO - We will want to display the screen to allow us to select an image or take a screenshot
    } else {
      stdout.printf( "Setting video.file to %s\n", video_item.get_resource_filename() ?? "N/A" );
      _video.file = File.new_for_path( video_item.get_resource_filename() );
    }

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( _video );
    box.set_size_request( -1, 500 );
    box.add_css_class( "themed" );

    /*
    var click_id = video_click.pressed.connect((n_press, x, y) => {
      if( n_press == 1 ) {
        _video.grab_focus();
      } else if( n_press == 2 ) {
        // TBD - show_video();
      }
    });
    add_signal( video_click, click_id );
    */

    var enter_id = video_focus.enter.connect(() => {
      set_as_current( true );
    });
    add_signal( video_focus, enter_id );

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

    var uri_id = video_item.notify["uri"].connect(() => {
      _video.file = File.new_for_path( video_item.get_resource_filename() );
    });
    add_signal( video_item, uri_id );

    handle_key_events( _video );

    return( box );

  }

  //-------------------------------------------------------------
  // Performs note search over this item.
  public override void do_search( NoteSearchFunc command ) {
    command( this, "desc", video_item.description, _h2_label );
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
