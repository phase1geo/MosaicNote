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

	private SidebarFavorites _favorites;
	private SidebarNotebooks _notebooks;
	private SidebarTags      _tags;

	// Default constructor
  public Sidebar() {

  	// Favorites section
  	_favorites = new SidebarFavorites();
  	append( _favorites );

  	// Notebooks section
  	_notebooks = new SidebarNotebooks();
  	append( _notebooks );

  	// Tags section
  	_tags = new SidebarTags();
  	append( _tags );

  }
	
}
