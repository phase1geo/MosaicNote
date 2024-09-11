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

public class UndoNoteMove : UndoItem {

  private Note     _note;
  private Notebook _notebook;

  //-------------------------------------------------------------
  // Default constructor
  public UndoNoteMove( Note note ) {
    base( _( "Move Note" ) );
    _note     = note;
    _notebook = note.notebook;
  }

  //-------------------------------------------------------------
  // Moves the stored notebook to the given notebook.
  private void toggle( MainWindow win ) {
    var tmp = _note.notebook;
    _notebook.move_note( _note );
    _notebook = tmp;
    if( (_note.notebook == win.notes.current) || (_notebook == win.notes.current) ) {
      win.notes.populate_with_notebook( win.notes.current, true );
    }
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( MainWindow win ) {
    toggle( win );
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( MainWindow win ) {
    toggle( win );
  }

}
