/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

using GLib;

public class UndoRowDelete : UndoItem {

  private Note        _note;
  private NoteItemRow _row;
  private int         _row_pos;

  //-------------------------------------------------------------
  // Default constructor
  public UndoRowDelete( Note note, int row ) {
    base( _( "Delete Row" ) );
    _note    = note;
    _row     = note.get_row( row );
    _row_pos = row;
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( MainWindow win ) {
    _note.add_row( _row, _row_pos );
    for( int i=0; i<_row.size(); i++ ) {
      var item = _row.get_item( i );
      win.note.items.add_pane( item, _row_pos, i, (i != 0), true );
    }
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( MainWindow win ) {
    var pane = win.note.items.get_pane( _row_pos, 0 );
    pane.remove_row( true, false );
  }

}
