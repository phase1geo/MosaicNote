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
	private NotebookTree.Node? _selected_node = null;
	private GLib.ListStore     _store;

  public signal void notebook_selected( Notebook nb );

	// Default constructor
	public SidebarNotebooks( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;
		_win.notebooks.changed.connect( populate_tree );

    var factory = new SignalListItemFactory();
    factory.setup.connect( setup_tree );
    factory.bind.connect( bind_tree );
    
    _store        = new GLib.ListStore( typeof( NotebookTree.Node ) );
    var model     = new TreeListModel( _store, false, false, add_tree_node );
    var selection = new SingleSelection( model ) {
    	autoselect = false,
    	can_unselect = true
    };
		var list_view = new ListView( selection, factory ) {
			margin_top = 10,
			single_click_activate = true
		};

		list_view.activate.connect((index) => {
			stdout.printf( "index: %u\n", index );
			_selected_node = _win.notebooks.get_node( (int)index );
			notebook_selected( _selected_node.get_notebook() );
		});

		var label = new Label( Utils.make_title( _( "Notebooks" ) ) ) {
			halign = Align.START,
			hexpand = true,
      use_markup = true
		};

    append( label );
    append( list_view );

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
      _win.notebooks.add_notebook( nb );
      remove( entry );
      notebook_selected( nb );
    });

    append( entry );

    entry.grab_focus();

	}

  // Clears the currently selected notebook
  public void clear_selection() {
  	// TBD
  }

  public void select_notebook( int id ) {
    // FOOBAR
  }

	// Populates the notebook tree with the updated version of win.notebooks
	private void populate_tree() {
		_store.remove_all();
		for( int i=0; i<_win.notebooks.size(); i++ ) {
			var node = _win.notebooks.get_node( i );
			_store.append( node );
  	}
	}

	private void setup_tree( Object obj ) {

		var item  = (ListItem)obj;
    var label = new Label( null ) {
    	halign = Align.START
    };

    var count = new Label( null ) {
    	halign = Align.END,
    	hexpand = true
    };

    count.add_css_class( "tag-count" );
    count.add_css_class( _win.themes.dark_mode ? "tag-count-dark" : "tag-count-light" );

  	_win.themes.theme_changed.connect((theme) => {
  		count.remove_css_class( _win.themes.dark_mode ? "tag-count-light" : "tag-count-dark" );
  		count.add_css_class( _win.themes.dark_mode ? "tag-count-dark" : "tag-count-light" );
 		});

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( label );
    box.append( count );

    var expander = new TreeExpander() {
    	margin_top = 5,
    	margin_bottom = 5,
    	child = box
    };

    item.child = expander;

	}

	private void bind_tree( Object obj ) {
		var item     = (ListItem)obj;
		var expander = (TreeExpander)item.child;
		var box      = (Box)expander.child;
		var label    = (Label)Utils.get_child_at_index( box, 0 );
		var count    = (Label)Utils.get_child_at_index( box, 1 );
		var row      = (TreeListRow)item.get_item();
		var node     = (NotebookTree.Node)row.get_item();

		expander.set_list_row( row );
		label.label = node.name;
		count.label = node.get_notebook().size().to_string();
	}

	// Create expander tree
	public ListModel? add_tree_node( Object obj ) {
		if( obj != null ) {
  		var node = (NotebookTree.Node)obj;
  		if( node.size() > 0 ) {
  			var store = new GLib.ListStore( typeof( NotebookTree.Node ) );
	  		for( int i=0; i<node.size(); i++ ) {
		  		store.append( node.get_node( i ) );
			  }
			  return( store );
			}
		}
  	return( null );
	}

}