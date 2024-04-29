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

public class NoteItem {

	public string name     { get; private set; default = ""; }
	public string label    { get; private set; default = ""; }
	public bool   modified { get; protected set; default = false; }

	// Default constructor
	public NoteItem( string name, string label ) {
    this.name  = name;
    this.label = label;
	}

	// Used for string searching
	public virtual bool search( string str ) {
	  return( false );	
	}

	// Saves this note item
	public virtual Xml.Node* save() {
		Xml.Node* node = new Xml.Node( null, name );
		modified = false;
		return( node );
	}

}