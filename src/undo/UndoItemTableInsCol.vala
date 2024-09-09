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

public class UndoItemTableInsCol : UndoItem {

  private NoteItemTable     _item;
  private int               _index;
  private string            _header;
  private Gtk.Justification _justify;
  private TableColumnType   _type;

  /* Default constructor */
  public UndoItemTableInsCol( NoteItemTable item, int index ) {

    base( _( "Insert Table Column" ) );

    _item  = item;
    _index = index;

    var col  = item.get_column( index );
    _header  = col.header;
    _justify = col.justify;
    _type    = col.data_type;

  }

  /* Causes the stored item to be put into the before state */
  public override void undo( MainWindow win ) {
    _item.delete_column( _index );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( MainWindow win ) {
    _item.insert_column( _index, _header, _justify, _type );
  }

}
