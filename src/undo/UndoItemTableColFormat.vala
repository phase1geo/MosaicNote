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

public class UndoItemTableColFormat : UndoItem {

  private NoteItemPaneTable _pane;
  private NoteItemTable     _item;
  private string            _id;
  private int               _index;
  private string            _header;
  private Gtk.Justification _justify;
  private TableColumnType   _type;

  /* Default constructor */
  public UndoItemTableColFormat( NoteItemPaneTable pane, NoteItemTable item, string id, int index ) {

    base( _( "Format Table Column" ) );

    _pane  = pane;
    _item  = item;
    _id    = id;
    _index = index;

    var col  = item.get_column( index );
    _header  = col.header;
    _justify = col.justify;
    _type    = col.data_type;

  }

  //-------------------------------------------------------------
  // Specifies if the column formatting changed.
  public bool changed( NoteItemTableColumn col ) {
    return( (col.header != _header) || (col.justify != _justify) || (col.data_type != _type) );
  }

  //-------------------------------------------------------------
  // Toggles the format information.
  private void toggle( MainWindow win ) {
    var col = _item.get_column( _index );
    if( col.data_type != _type ) {
      var tmp = col.data_type;
      col.data_type = _type;
      _type = tmp;
      _pane.column_type_changed( _id );
    }
    if( col.header != _header ) {
      var tmp = col.header;
      col.header = _header;
      _header = tmp;
      _pane.column_title_changed( _id );
    }
    if( col.justify != _justify ) {
      var tmp = col.justify;
      col.justify = _justify;
      _justify = tmp;
      _pane.column_justify_changed( _id );
    }
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( MainWindow win ) {
    toggle( win );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( MainWindow win ) {
    toggle( win );
  }

}
