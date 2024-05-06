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

public class SidebarFavorites : Box {

	private MainWindow _win;
	private ListBox    _lb;

	// Default constructor
	public SidebarFavorites( MainWindow win ) {

		Object( orientation: Orientation.VERTICAL, spacing: 5 );

		_win = win;

		// Create listbox
    _lb = new ListBox() {
    	margin_top = 10
    };

    _lb.bind_model( _win.favorites.model, create_favorite );

		var expander = new Expander( Utils.make_title( _( "Favorites" ) ) ) {
			use_markup = true,
			child = _lb
		};

		append( expander );

	}

	// Returns a widget containing the name of the notebook/note that the given favorite represents
	private Widget create_favorite( Object item ) {
		var fav = (Favorite)item;
		var name = new Label( fav.get_name( _win.notebooks ) );
		return( name );
	}

}