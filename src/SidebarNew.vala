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

public class SidebarNew : Box {

	private MainWindow     _win;
	private BaseNotebook?  _selected_node = null;
	private GLib.ListStore _store;
	private ListView       _list_view;

  public signal void notebook_selected( BaseNotebook nb );

	// Default constructor
	public SidebarNew( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;
		_win.notebooks.changed.connect( populate_tree );

    var factory = new SignalListItemFactory();
    factory.setup.connect( setup_tree );
    factory.bind.connect( bind_tree );
    
    _store        = new GLib.ListStore( typeof( BaseNotebook ) );
    var model     = new TreeListModel( _store, false, false, add_tree_node );
    var selection = new SingleSelection( model );

		_list_view = new ListView( selection, factory ) {
			margin_top = 10,
			single_click_activate = true
		};

		_list_view.activate.connect((pos) => {
			var row = model.get_row( pos );
			var nb  = (BaseNotebook)row.get_item();
			notebook_selected( nb );
		});

    append( _list_view );

    var add_nb_btn = new Button.from_icon_name( "list-add-symbolic" ) {
  		halign = Align.START,
  		has_frame = false
  	};

  	add_nb_btn.clicked.connect(() => {
  		add_notebook();
		});

  	var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
  		valign = Align.END,
  		vexpand = true
  	};
  	bbox.append( add_nb_btn );

  	append( bbox );

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
  	_list_view.model.unselect_all();
  }

	// Populates the notebook tree with the updated version of win.notebooks
	private void populate_tree() {

		_store.remove_all();

		var library = new BaseNotebook( _( "Library" ) );
		_store.append( library );

		for( int i=0; i<_win.smart_notebooks.size(); i++ ) {
      var notebook = _win.smart_notebooks.get_notebook( i );
      if( notebook.notebook_type == SmartNotebookType.BUILTIN ) {
      	_store.append( notebook );
      }
		}

		var notebooks = new BaseNotebook( _( "Notebooks" ) );
		_store.append( notebooks );

		for( int i=0; i<_win.notebooks.size(); i++ ) {
			var node = _win.notebooks.get_node( i );
			_store.append( node );
  	}

  	var tags = new BaseNotebook( _( "Tags" ) );
  	_store.append( tags );

		for( int i=0; i<_win.full_tags.size(); i++ ) {
			_store.append( _win.full_tags.get_tag( i ) );
		}

	}

	private void setup_tree( Object obj ) {

		var item  = (ListItem)obj;

    var label = new Label( null ) {
    	halign = Align.START
    };

    var count = new Label( null ) {
    	halign = Align.END,
    	hexpand = true,
    	margin_end = 5
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
    	margin_top = 2,
    	margin_bottom = 2,
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
		var nb       = (BaseNotebook)row.get_item();

		if( ((nb as NotebookTree.Node) == null) && ((nb as SmartNotebook) == null) && ((nb as FullTag) == null) ) {
			item.selectable   = false;
			item.activatable  = false;
			// item.focusable    = false;
			label.label       = Utils.make_title( nb.name );
			label.use_markup  = true;
			label.margin_start = 5;
			count.visible     = false;
			box.margin_top    = 10;
			box.margin_bottom = 10;
		} else {
		  expander.set_list_row( row );
		  label.label = nb.name;
		  count.label = nb.count().to_string();
		  if( nb.count() == 0 ) {
		  	expander.margin_top = 6;
		  	expander.margin_bottom = 6;
		  	count.visible = false;
		  }
		}

	}

	// Create expander tree
	public ListModel? add_tree_node( Object obj ) {
		if( (obj != null) && ((obj as NotebookTree.Node) != null) ) {
  		var node = (NotebookTree.Node)obj;
   		if( node.size() > 0 ) {
 	  		var store = new GLib.ListStore( typeof( BaseNotebook ) );
  	  	for( int i=0; i<node.size(); i++ ) {
	  	  	store.append( node.get_node( i ) );
		    }
		    return( store );
		  }
		}
  	return( null );
	}

}