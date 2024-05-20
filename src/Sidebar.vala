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

public class Sidebar : Box {

	private SidebarBuiltins  _builtins;
	private SidebarNotebooks _notebooks;
	private SidebarTags      _tags;

	public signal void selected_notebook( Notebook nb );
  public signal void selected_smart_notebook( SmartNotebook nb );

	// Default constructor
  public Sidebar( MainWindow win ) {

  	Object( orientation: Orientation.VERTICAL, spacing: 20, margin_top: 5, margin_bottom: 5, margin_start: 5, margin_end: 5 );

  	// Favorites section
  	_builtins = new SidebarBuiltins( win );
    _builtins.notebook_selected.connect((nb) => {
      _notebooks.clear_selection();
      _tags.clear_selection();
      selected_smart_notebook( nb );
    });
  	append( _builtins );

  	// Notebooks section
  	_notebooks = new SidebarNotebooks( win );
  	_notebooks.notebook_selected.connect((nb) => {
      _builtins.clear_selection();
      _tags.clear_selection();
  		selected_notebook( nb );
 		});
  	append( _notebooks );

  	// Tags section
  	_tags = new SidebarTags( win );
    _tags.notebook_selected.connect((nb) => {
      _builtins.clear_selection();
      _notebooks.clear_selection();
      selected_smart_notebook( nb );
    });
  	append( _tags );

  	var add_nb_btn = new Button.from_icon_name( "list-add-symbolic" ) {
  		halign = Align.START,
  		has_frame = false
  	};

  	add_nb_btn.clicked.connect(() => {
  		_notebooks.add_notebook();
		});

  	var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
  		valign = Align.END,
  		vexpand = true
  	};
  	bbox.append( add_nb_btn );
  	append( bbox );

  }

  public void select_notebook_and_note( int notebook_id, int note_id ) {
    _notebooks.select_notebook( notebook_id );
  }
	
}
