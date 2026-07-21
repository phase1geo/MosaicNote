/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

public class UndoItemMove : UndoItem {

  private NoteItemPane  _pane;
  private MoveDirection _move_dir;

  //-------------------------------------------------------------
  // Default constructor
  public UndoItemMove( NoteItemPane pane, MoveDirection move_dir ) {
    base( _( "Move Block" ) );
    _pane     = pane;
    _move_dir = move_dir;
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state
  public override void undo( MainWindow win ) {
    switch( _move_dir ) {
      case MoveDirection.UP    :  _pane.move_item( MoveDirection.DOWN,  false );  break;
      case MoveDirection.DOWN  :  _pane.move_item( MoveDirection.UP,    false );  break;
      case MoveDirection.LEFT  :  _pane.move_item( MoveDirection.RIGHT, false );  break;
      case MoveDirection.RIGHT :  _pane.move_item( MoveDirection.LEFT,  false );  break;
      default                  :  break;
    }
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the after state
  public override void redo( MainWindow win ) {
    _pane.move_item( _move_dir, false );
  }

}
