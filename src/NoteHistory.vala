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

//-------------------------------------------------------------
// Holds the history of viewed notes in the NotePanel.
public class NoteHistory {

  private Array<Note> _history;
  private int         _ptr = -1;

  public signal void goto_note( Note note );

  //-------------------------------------------------------------
  // Default constructor
  public NoteHistory() {
    _history = new Array<Note>();
    _ptr     = -1;
  }

  //-------------------------------------------------------------
  // Adds a new item to the note history.
  public void push_note( Note note ) {

    // Remove all history newer than the current pointer
    if( can_go_forward() ) {
      _history.remove_range( (_ptr + 1), (_history.length - (_ptr + 1)) );
    }

    // Add the note to the end of history
    _history.append_val( note );
    _ptr++;

  }

  //-------------------------------------------------------------
  // Returns true if we can go backwards in history
  public bool can_go_backward() {
    return( _ptr > 0 );
  }

  //-------------------------------------------------------------
  // Returns true if we can go forwards in history
  public bool can_go_forward() {
    return( (_ptr + 1) < _history.length );
  }

  //-------------------------------------------------------------
  // Displays the previous note in history
  public void go_backward() {
    if( can_go_backward() ) {
      goto_note( _history.index( --_ptr ) );
    }
  }

  //-------------------------------------------------------------
  // Displays the next note in history
  public void go_forward() {
    if( can_go_forward() ) {
      goto_note( _history.index( ++_ptr ) );
    }
  }

}