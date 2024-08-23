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

public class UndoNoteTagAdd : UndoItem {

  private Note   _note;
  private string _tag;

  /* Default constructor */
  public UndoNoteTagAdd( Note note, string tag ) {
    base( _( "Add Tag" ) );
    _note = note;
    _tag  = tag;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( MainWindow win ) {
    _note.tags.delete_tag( _tag );
    win.note.tags.add_tags( _note.tags );
    win.note.tag_removed( _tag, _note.id );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( MainWindow win ) {
    _note.tags.add_tag( _tag );
    win.note.tags.add_tags( _note.tags );
    win.note.tag_added( _tag, _note.id );
  }

}
