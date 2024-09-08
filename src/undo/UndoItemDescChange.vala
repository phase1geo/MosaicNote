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

public class UndoItemDescChange : UndoItem {

  private NoteItem _item;
  private string   _text;

  /* Default constructor */
  public UndoItemDescChange( NoteItem item, string text ) {
    base( _( "Change Item Description" ) );
    _item  = item;
    _text  = text;
  }

  //-------------------------------------------------------------
  // Toggles description between the one that is stored and the
  // one in the note item.
  private void toggle( MainWindow win ) {
    var tmp   = _text;
    var code  = (_item as NoteItemCode);
    var image = (_item as NoteItemImage);
    var uml   = (_item as NoteItemUML);
    var math  = (_item as NoteItemMath);
    var table = (_item as NoteItemTable);
    if( code != null ) {
      tmp = code.description;
      code.description = _text;
    } else if( image != null ) {
      tmp = image.description;
      image.description = _text;
    } else if( uml != null ) {
      tmp = uml.description;
      uml.description = _text;
    } else if( math != null ) {
      tmp = math.description;
      math.description = _text;
    } else if( table != null ) {
      tmp = table.description;
      table.description = _text;
    }
    _text = tmp;
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
