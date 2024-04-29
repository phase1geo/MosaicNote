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

public class NoteItemMarkdown : NoteItem {

	private string _content = "";

	public string content {
	  get {
	  	return( _content );
   	}
   	set {
   		if( _content != value ) {
   			content  = value;
   			modified = true;
   		}
   	}
  }

	// Default constructor
	public NoteItemMarkdown() {
		base( "markdown", _( "Markdown" ) );
	}

	public NoteItemMarkdown.from_xml( Xml.Node* node ) {
		base( "markdown", _( "Markdown" ) );
		load( node );
	}

	// Searches the content for the given string
	public override bool search( string str ) {
		return( content.contains( str ) );
	}

	// Saves the content in XML format
	public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->add_content( content );
    return( node );
	}

	// Loads the content from XML format
	private void load( Xml.Node* node ) {
    content = node->get_content();
	}

}