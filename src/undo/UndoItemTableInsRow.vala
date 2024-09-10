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

public class UndoItemTableInsRow : UndoItem {

  private NoteItemTable     _item;
  private int               _index;
  private NoteItemTableRow  _row;

  /* Default constructor */
  public UndoItemTableInsRow( NoteItemTable item, int index ) {

    base( _( "Insert Table Row" ) );

    _item  = item;
    _index = index;
    _row   = item.get_row( index );

  }

  /* Causes the stored item to be put into the before state */
  public override void undo( MainWindow win ) {
    _item.delete_row( _index );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( MainWindow win ) {
    _item.insert_row( _index, _row );
  }

}
