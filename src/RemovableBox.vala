/*
* Copyright (c) 2026 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
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

using Gtk;

public class SignalConnection {
  public Object obj { get; private set; }
  public ulong  id  { get; private set; default = 0; }
  public SignalConnection( Object o, ulong i ) {
    obj = o;
    id  = i;
  }
}

public class RemovableBox : Box {

  private Array<SignalConnection> _connections;

  //-------------------------------------------------------------
  // Constructor
  public RemovableBox( Orientation orientation, int spacing ) {
    Object( orientation: orientation, spacing: spacing );
    _connections = new Array<SignalConnection>();
  }

  //-------------------------------------------------------------
  // Must be called before the Box is destroyed.  Recursively
  // traverses widget tree to cleanup all children.
  public virtual void cleanup() {

    // Cleanup our signals
    for( int i=0; i<_connections.length; i++ ) {
      var conn = _connections.index( i );
      SignalHandler.disconnect( conn.obj, conn.id );
    }
    _connections.remove_range( 0, _connections.length );

    // Recursively cleanup items within this box
    var child = get_first_child();
    while( child != null ) {
      var box = (child as RemovableBox);
      if( box != null ) {
        box.cleanup();
      }
      child = child.get_next_sibling();
    } 

  }

  //-------------------------------------------------------------
  // Adds a signal for an item that is tracked by this widget.
  public void add_signal( Object obj, ulong id ) {
    var connection = new SignalConnection( obj, id );
    _connections.append_val( connection );
  }

}
