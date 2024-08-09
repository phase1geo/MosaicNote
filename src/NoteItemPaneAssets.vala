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
    /*
    place_cursor( _text, placement );
    _text.grab_focus();
    */
  }

  //-------------------------------------------------------------
  // Adds a new Markdown item at the given position in the content area
  protected override Widget create_pane() {

    // TBD

    var box = new Box( Orientation.VERTICAL, 5 );

    return( box );

  }

}