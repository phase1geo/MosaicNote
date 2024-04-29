/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
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

public class SidebarNotebooks : Box {

	private MainWindow _win;

	// Default constructor
	public SidebarNotebooks( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;

		var expander = new Expander( _( "Notebooks" ) );

		for( int i=0; i<_win.notebooks.size(); i++ ) {
			var node = _win.notebooks.get_node( i );
  		expander.child = make_expand_tree( node );
  	}

    append( expander );

	}

	// Create expander tree
	public Box? make_expand_tree( NotebookTree.Node parent ) {

		if( parent.size() > 0 ) {

  		var box = new Box( Orientation.VERTICAL, 5 );

		  for( int i=0; i<parent.size(); i++ ) {
			  var child    = parent.get_child( i );
			  var expander = new Expander( child.name ) {
				  child = make_expand_tree( child )
			  };
			  append( expander );
		  }

		  return( box );

		}

		return( null );

	}

}