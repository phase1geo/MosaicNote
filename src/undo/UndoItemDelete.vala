/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
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

public class UndoItemDelete : UndoItem {

  private Note     _note;
  private NoteItem _item;
  private int      _index;

  /* Default constructor */
  public UndoItemDelete( Note note, int index ) {
    base( _( "Delete Block" ) );
    _note  = note;
    _item  = note.get_item( index );
    _index = index;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( MainWindow win ) {
    _note.add_note_item( _index, _item );
    win.note.items.add_item( _item, _index );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( MainWindow win ) {
    var pane = win.note.items.get_pane( _index );
    pane.remove_item( true, false );
  }

}
