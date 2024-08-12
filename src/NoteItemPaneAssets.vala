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
using Gee;

//-------------------------------------------------------------
// Note item pane that represents asset links.
public class NoteItemPaneAssets : NoteItemPane {

  private Button  _add;
  private ListBox _listbox;
  private Box     _drop_box;

  public NoteItemAssets assets_item {
    get {
      return( (NoteItemAssets)item );
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneAssets( MainWindow win, NoteItem item, SpellChecker spell ) {
    base( win, item, spell );
  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    if( assets_item.size() > 0 ) {
      _listbox.grab_focus();
      _listbox.select_row( _listbox.get_row_at_index( 0 ) );
    } else {
      _add.grab_focus();
    }
    _drop_box.visible = true;
  }

  //-------------------------------------------------------------
  // Adds the given asset to the listbox.
  private void add_asset( string uri, bool add_to_item ) {

    var label = new Label( Filename.display_basename( uri ) ) {
      halign = Align.START,
      hexpand = true,
      ellipsize = Pango.EllipsizeMode.MIDDLE,
      tooltip_text = uri
    };

    _listbox.append( label );

    if( add_to_item ) {
      assets_item.add_asset( uri );
    }

  }

  //-------------------------------------------------------------
  // Displays a dialog to request
  private void show_file_dialog() {

#if GTK410
    var dialog = Utils.make_file_chooser( _( "Select File" ), _( "Select" ) );

    dialog.open.begin( win, null, (obj, res) => {
      try {
        var file = dialog.open.end( res );
        if( file != null ) {
          add_asset( file.get_uri(), true );
        }
      } catch( Error e ) {}
    });
#else
    var dialog = Utils.make_file_chooser( _( "Select File" ), win, FileChooserAction.OPEN, _( "Select" ) );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var file = dialog.get_file();
        if( file != null ) {
          add_asset( file.get_uri(), true );
        }
      }
      dialog.destroy();
    });

    dialog.show();
#endif

  }

  //-------------------------------------------------------------
  // Returns true if the listbox will use the up key event.
  protected override bool handled_up() {
    var row = _listbox.get_selected_row();
    return( (row != null) && (row.get_index() > 0) );
  }

  //-------------------------------------------------------------
  // Returns true if the listbox will use the down key event.
  protected override bool handled_down() {
    var row = _listbox.get_selected_row();
    return( (row != null) && (row.get_index() < (assets_item.size() - 1)));
  }

  //-------------------------------------------------------------
  // Add elements to the note item header bar
  protected override Widget create_header1() {

    _add = new Button.from_icon_name( "list-add-symbolic" ) {
      halign       = Align.END,
      hexpand      = true,
      tooltip_text = _( "Add assets" )
    };

    _add.clicked.connect(() => {
      show_file_dialog();
    });

    return( _add );

  }

  //-------------------------------------------------------------
  // Called when our item box loses focus.
  public override void clear_current() {
    base.clear_current();
    _drop_box.visible = false;
    _listbox.select_row( null );
  }

  //-------------------------------------------------------------
  // Adds a new Markdown item at the given position in the content area
  protected override Widget create_pane() {

    var label = new Label( Utils.make_title( _( "Files" ) ) ) {
      halign     = Align.START,
      hexpand    = true,
      use_markup = true,
      can_focus  = true,
      focusable  = true
    };

    var focus = new EventControllerFocus();
    var key   = new EventControllerKey();

    _listbox = new ListBox() {
      halign  = Align.START,
      hexpand = true,
      selection_mode = SelectionMode.SINGLE,
      activate_on_single_click = false
    };
    _listbox.add_controller( key );
    _listbox.add_controller( focus );

    _listbox.row_activated.connect((row) => {
      var uri = assets_item.get_asset( row.get_index() );
      Utils.open_url( uri );
    });

    key.key_pressed.connect((keyval, keycode, state) => {
      var row = _listbox.get_selected_row();
      if( row != null ) {
        if( (keyval == Gdk.Key.Delete) || (keyval == Gdk.Key.BackSpace) ) {
          assets_item.remove_asset( row.get_index() );
          _listbox.remove( row );
          return( true );
        }
      }
      return( false );
    });

    focus.enter.connect(() => {
      set_as_current();
      _drop_box.visible = true;
    });

    var drop_label = new Label( _( "Drag file or URL here to add" ) ) {
      halign = Align.CENTER,
      hexpand = true,
      margin_top = 10,
      margin_bottom = 10
    };

    _drop_box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign        = Align.FILL,
      margin_start  = 5,
      margin_end    = 5,
      margin_bottom = 5
    };
    _drop_box.append( drop_label );
    _drop_box.add_css_class( "drop-area" );

    var drop = new DropTarget( typeof( File ), Gdk.DragAction.COPY );
    _drop_box.add_controller( drop );

    drop.drop.connect((val, x, y) => {
      var file = (File)val.get_object();
      if( file != null ) {
        add_asset( file.get_uri(), true );
        return( true );
      }
      return( false );
    });

    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( label );
    box.append( _listbox );
    box.append( _drop_box );

    for( int i=0; i<assets_item.size(); i++ ) {
      var asset = assets_item.get_asset( i );
      add_asset( asset, false );
    }

    handle_key_events( _listbox );

    return( box );

  }

}