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

	private MainWindow         _win;
	private ListBox            _node_box;
	private NotebookTree.Node? _selected_node = null;
	private ListBox?           _selected_lb   = null;

  public signal void notebook_selected( Notebook nb );

	// Default constructor
	public SidebarNotebooks( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;
		_win.notebooks.changed.connect( populate_tree );

		_node_box = new ListBox() {
			selection_mode = SelectionMode.SINGLE
		};

		_node_box.row_selected.connect((row) => {
			if( row != null ) {
				_selected_node = _win.notebooks.get_node( row.get_index() );
				_selected_lb   = _node_box;
				notebook_selected( _selected_node.get_notebook() );
			}
   	});

		var expander = new Expander( _( "Notebooks" ) ) {
			halign = Align.START,
			hexpand = true,
			expanded = true,
			child = _node_box
		};

    append( expander );

    // Go ahead and populate ourselves to get started
    populate_tree();

	}

	// Adds a new notebook to the end of the list
	public void add_notebook() {

    var entry = new Entry() {
      placeholder_text = _( "Enter notebook name" )
    };

    entry.activate.connect(() => {
      var nb = new Notebook( entry.text );
      if( _selected_node == null ) {
        _win.notebooks.add_notebook( nb );
      } else {
      	_selected_node.add_notebook( nb );
      }
      notebook_selected( nb );
    });

    if( _selected_lb == null ) {
      _node_box.append( entry );
    } else {
    	var row = _selected_lb.get_selected_row();
      _selected_lb.insert( entry, (row.get_index() + 1) );
    }

    entry.grab_focus();

	}

	// Populates the notebook tree with the updated version of win.notebooks
	private void populate_tree() {
		_node_box.remove_all();
		for( int i=0; i<_win.notebooks.size(); i++ ) {
			var node = _win.notebooks.get_node( i );
  		_node_box.append( make_expand_tree( node, 1 ) );
  	}
	}

	// Create expander tree
	public Widget make_expand_tree( NotebookTree.Node node, int depth ) {

		int margin = 20;

		if( node.size() > 0 ) {

  		var box = new ListBox() {
  			selection_mode = SelectionMode.SINGLE
  		};

  		box.row_selected.connect((row) => {
  			if( row != null ) {
    			_selected_node = node.get_child( row.get_index() );
    			_selected_lb   = box;
				  notebook_selected( _selected_node.get_notebook() );
    		}
			});

      var expander = new Expander( node.name ) {
				halign = Align.START,
				hexpand = true,
      	margin_start = (depth * margin),
      	child = box,
      	expanded = node.expanded
      };

      expander.activate.connect(() => {
      	node.expanded = expander.expanded;
      });

		  for( int i=0; i<node.size(); i++ ) {
			  box.append( make_expand_tree( node.get_child( i ), (depth + 1) ) );
		  }

		  return( expander );

		} else {

			var label = new Label( node.name ) {
				halign = Align.START,
				hexpand = true,
				margin_start = (depth * margin)
			};

			return( label );
		}

	}

}