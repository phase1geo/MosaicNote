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

public class UndoItemAdd : UndoItem {

  private Note     _note;
  private NoteItem _item;
  private int      _row;
  private int      _col;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemAdd( Note note, int row, int col ) {
    base( _( "Add Block" ) );
    _note = note;
    _item = note.get_item( row, col );
    _row  = row;
    _col  = col;
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( MainWindow win ) {
    var pane = win.note.items.get_pane( _row, _col );
    pane.remove_item( true, false );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( MainWindow win ) {
    var add_to_row = (_item.row.size() > 0);
    _note.add_item( _item, _row, _col, add_to_row );
    win.note.items.add_pane( _item, _row, _col, add_to_row, true );
  }

}
