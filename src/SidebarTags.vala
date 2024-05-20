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

public class SidebarTags : Box {

	private MainWindow _win;
	private ListBox    _lb;

  public signal void notebook_selected( SmartNotebook? nb );

	// Default constructor
	public SidebarTags( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;

		_lb = new ListBox() {
			margin_top = 10,
			selection_mode = SelectionMode.SINGLE,
      activate_on_single_click = true
		};
		_lb.row_selected.connect( tag_selected );

		var expander = new Expander( Utils.make_title( _( "Tags" ) ) ) {
			use_markup = true,
			expanded = (_win.full_tags.size() > 0),
			child = _lb
		};

		append( expander );

		// If the list of tags changes, update the listbox
		_win.full_tags.changed.connect( populate_listbox );

		// Initially populate the listbox
		populate_listbox();

	}

  // Clears the current selection
  public void clear_selection() {
    _lb.select_row( null );
  }

	// Adds the full list of tags to the listbox
	private void populate_listbox() {

		// _lb.remove_all();
		Utils.clear_listbox( _lb );

		for( int i=0; i<_win.full_tags.size(); i++ ) {
			_lb.append( create_tag( _win.full_tags.get_tag( i ) ) );
		}

	}

	// Creates a tag
	private Box create_tag( FullTag tag ) {

  	var name = new Label( tag.name ) {
      halign  = Align.START,
      hexpand = true
  	};
  	var count = new Label( tag.count().to_string() ) {
  		halign = Align.END
  	};
  	count.add_css_class( "tag-count" );
  	count.add_css_class( _win.themes.dark_mode ? "tag-count-dark" : "tag-count-light" );

  	_win.themes.theme_changed.connect((theme) => {
  		count.remove_css_class( _win.themes.dark_mode ? "tag-count-light" : "tag-count-dark" );
  		count.add_css_class( _win.themes.dark_mode ? "tag-count-dark" : "tag-count-light" );
 		});

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
    	margin_start  = 20,
    	margin_top    = 1,
    	margin_bottom = 1,
    	halign        = Align.FILL
    };
    box.append( name );
    box.append( count );

    return( box );

	}

	// Called whenever the user selects a tag in this widget.  We will take care to search
	// and populate the notes panel with a list of notes that contain the given tag.
	private void tag_selected( ListBoxRow? row ) {

		if( row == null ) {
      notebook_selected( null );
		} else {
      var index = row.get_index();
      var count = 0;
      for( int i=0; i<_win.smart_notebooks.size(); i++ ) {
        var notebook = _win.smart_notebooks.get_notebook( i );
        if( (notebook.notebook_type == SmartNotebookType.TAG) && (index == count) ) {
          notebook_selected( notebook );
        }
        count++;
      }
		}

	}

}