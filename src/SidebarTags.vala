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

	private FullTags _all_tags;
	private ListBox  _lb;

	// Default constructor
	public SidebarTags() {

		base( Orientation.VERTICAL );

		_lb = new Listbox();
		_lb.bind_model( _all_tags.get_model(), create_tag );

		var expander = new Expander( _( "Tags" ) ) {
			child = _all_tags.get_model();
		}

		append( expander );

	}

	// Creates a tag
	public Widget? create_tag( Object obj ) {

    var tag = (Tag)obj;

    if( tag != null ) {
    	var name = new Label( tag.name ) {
        halign  = Align.START,
        hexpand = true
    	};
    	var count = new Label( tag.count ) {
    		halign = Align.END
    	}
      var box = new Box( Orientation.HORIZONTAL ) {
      	halign  = Align.START,
      	hexpand = true
      };
      box.append( name );
      box.append( count );
      return( box );
    }

    return( null );

	}

}