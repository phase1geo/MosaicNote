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

  private ListBox _listbox;

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
    _listbox.grab_focus();
  }

  //-------------------------------------------------------------
  // Adds the given asset to the listbox.
  private void add_asset( string uri, bool add_to_item ) {
    var label  = new Label( Filename.display_basename( uri ) ) {
      ellipsize = Pango.EllipsizeMode.MIDDLE
    };
    var button = new LinkButton( Filename.display_basename( uri ) ) {
      halign = Align.START,
      hexpand = true,
      child = label
    };
    button.activate_link.connect(() => {
      button.visited = true;
      Utils.open_url( uri );
      return( true );
    });
    _listbox.append( button );
    if( add_to_item ) {
      assets_item.add_asset( uri );
    }
  }

  //-------------------------------------------------------------
  // Adds a new Markdown item at the given position in the content area
  protected override Widget create_pane() {

    _listbox = new ListBox() {
      halign  = Align.START,
      hexpand = true,
      selection_mode = SelectionMode.NONE
    };

    var drop_label = new Label( _( "Drag file or URL here to add" ) ) {
      halign = Align.CENTER,
      hexpand = true,
      margin_top = 20,
      margin_bottom = 20
    };

    var drop_box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL,
    };
    drop_box.append( drop_label );
    drop_box.add_css_class( "drop-area" );

    var drop = new DropTarget( typeof( File ), Gdk.DragAction.COPY );
    drop_box.add_controller( drop );

    drop.drop.connect((val, x, y) => {
      var file = (File)val.get_object();
      if( file != null ) {
        add_asset( file.get_uri(), true );
        return( true );
      }
      return( false );
    });

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _listbox );
    box.append( drop_box );

    for( int i=0; i<assets_item.size(); i++ ) {
      var asset = assets_item.get_asset( i );
      add_asset( asset, false );
    }

    return( box );

  }

}