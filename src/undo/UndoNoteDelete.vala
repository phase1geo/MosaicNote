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

public class UndoNoteDelete : UndoItem {

  private Notebook _notebook;
  private Note     _note;

  /* Default constructor */
  public UndoNoteDelete( Note note ) {
    base( _( "Delete Note" ) );
    _notebook = note.notebook;
    _note     = note;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo( MainWindow win ) {
    _note.notebook = _notebook;
    win.notes.add_note( _note );
  }

  /* Causes the stored item to be put into the after state */
  public override void redo( MainWindow win ) {
    win.notes.delete_note( _note, true );
  }

}
