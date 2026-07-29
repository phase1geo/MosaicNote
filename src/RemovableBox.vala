
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

  public RemovableBox( Orientation orientation, int spacing ) {
    Object( orientation: orientation, spacing: spacing );
    _connections = new Array<SignalConnection>();
  }

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

  public void add_signal( Object obj, ulong id ) {
    var connection = new SignalConnection( obj, id );
    _connections.append_val( connection );
  }

}
