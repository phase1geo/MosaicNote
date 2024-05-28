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

public class SidebarBuiltins : Box {

	private MainWindow _win;
	private ListBox    _lb;

  public signal void notebook_selected( SmartNotebook? notebook );

	// Default constructor
	public SidebarBuiltins( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;

    var motion = new EventControllerMotion();

		_lb = new ListBox() {
			margin_top = 10,
			selection_mode = SelectionMode.SINGLE,
      activate_on_single_click = true
		};
    _lb.add_controller( motion );
		_lb.row_activated.connect( list_selected );

    motion.enter.connect((x, y) => {
      _lb.grab_focus();
    });
    /*
    motion.motion.connect((x, y) => {
      var row = _lb.get_row_at_y( (int)y );
      _lb.select_row( row );
    });
    motion.leave.connect(() => {
      _lb.unselect_all();
    });
    */

		var label = new Label( Utils.make_title( _( "Library" ) ) ) {
			use_markup = true,
      xalign = (float)0
		};

		append( label );
    append( _lb );

		// Initially populate the listbox
		populate_listbox();

	}

  // Clears the current selection
  public void clear_selection() {
    _lb.select_row( null );
  }

	// Adds the full list of tags to the listbox
	private void populate_listbox() {

		Utils.clear_listbox( _lb );

		for( int i=0; i<_win.smart_notebooks.size(); i++ ) {
      var notebook = _win.smart_notebooks.get_notebook( i );
      if( notebook.notebook_type == SmartNotebookType.BUILTIN ) {
  			_lb.append( create_notebook( notebook ) );
      }
		}

	}

	// Creates a tag
	private Box create_notebook( SmartNotebook notebook ) {

  	var name = new Label( notebook.name ) {
      halign  = Align.START,
      hexpand = true
  	};
  	var count = new Label( notebook.count().to_string() ) {
  		halign  = Align.END
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
	private void list_selected( ListBoxRow? row ) {

		if( row == null ) {
      notebook_selected( null );
		} else {
      var index = row.get_index();
      var count = 0;
      for( int i=0; i<_win.smart_notebooks.size(); i++ ) {
        var notebook = _win.smart_notebooks.get_notebook( i );
        if( (notebook.notebook_type == SmartNotebookType.BUILTIN) && (index == count) ) {
          notebook_selected( notebook );
        }
        count++;
      }
		}

	}

}