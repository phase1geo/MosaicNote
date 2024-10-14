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

public class UndoTextChanges : UndoItem {

  private NoteItem _item;

  /* Default constructor */
  public UndoTextChanges( NoteItem item ) {
    base( _( "Text Change" ) );
    _item = item;
  }

  //-------------------------------------------------------------
  // Returns the pane currently associated with this item.
  private NoteItemPane get_pane( MainWindow win ) {
    return( win.note.items.get_pane( _item.index() ) );
  }

  //-------------------------------------------------------------
  // Only pop this item if the undo buffer is empty
  public override bool undo_done( MainWindow win ) {
    var pane = get_pane( win );
    var text = pane.get_text();
    return( !text.buffer.can_undo );
  }

  //-------------------------------------------------------------
  // Only pop this item if the redo buffer is empty
  public override bool redo_done( MainWindow win ) {
    var pane = get_pane( win );
    var text = pane.get_text();
    return( !text.buffer.can_redo );
  }

  //-------------------------------------------------------------
  // We can merge if ourselves and the given item are both text changes
  // and we are pointed at the same pane.
  public override bool mergeable( UndoItem item ) {
    var text_item = (item as UndoTextChanges);
    return( (text_item != null) && (_item == text_item._item) );
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( MainWindow win ) {
    var pane = get_pane( win );
    var text = pane.get_text();
    pane.ignore_text_change = true;
    text.buffer.undo();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( MainWindow win ) {
    var pane = get_pane( win );
    var text = pane.get_text();
    pane.ignore_text_change = true;
    text.buffer.redo();
  }

}
