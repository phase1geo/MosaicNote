/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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

public class NoteItemPaneRow : Box {

  private int _size = 0;

  public int size {
    get {
      return( _size );
    }
  }

  //-------------------------------------------------------------
  // Constructor
  public NoteItemPaneRow() {
    Object( orientation: Orientation.HORIZONTAL, spacing : 5, homogeneous : true );
  }

  //-------------------------------------------------------------
  // Populates this row with the given note.
  public void add_pane( NoteItemPane pane, int column = -1 ) {
    if( column == -1 ) {
      append( pane );
    } else if( column == 0 ) {
      prepend( pane );
    } else {
      var sibling = get_pane( column - 1 );
      insert_child_after( pane, sibling );
    }
    _size++;
  }

  //-------------------------------------------------------------
  // Deletes the item at the given column.
  public void delete_pane( int column ) {
    var box = get_pane( column );
    if( box != null ) {
      remove( box );
      _size--;
    }
  }

  //-------------------------------------------------------------
  // Returns the item at the given column
  public NoteItemPane? get_pane( int column ) {
    return( (NoteItemPane)Utils.get_child_at_index( this, column ) );
  }

}
