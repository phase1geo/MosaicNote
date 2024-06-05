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

public class NoteItemCode : NoteItem {

	private string _lang = "vala";  // TODO

	public string lang {
	  get {
	  	return( _lang );
	  }
	  set {
	  	if( _lang != value ) {
	  		_lang    = value;
        modified = true;
        changed();
	  	}
	  }
	}

	// Default constructor
	public NoteItemCode( Note note ) {
		base( note, NoteItemType.CODE );
	}

	// Constructor from XML node
	public NoteItemCode.from_xml( Note note, Xml.Node* node ) {
		base( note, NoteItemType.CODE );
		load( node );
	}

	// Copies the note item to this one
  public override void copy( NoteItem item ) {
    base.copy( item );
    var code = (item as NoteItemCode);
    if( code != null ) {
      this._lang = code._lang;
    }
  }

  // Returns the Markdown version of this item
  public override string to_markdown() {
  	return( "``` %s\n%s\n```".printf( _lang, content ) );
  }

	// Saves the content in XML format
	public override Xml.Node* save() {
    Xml.Node* node = base.save();
    node->set_prop( "lang", lang );
    return( node );
	}

	// Loads the content from XML format
	protected override void load( Xml.Node* node ) {
    base.load( node );
		var l = node->get_prop( "lang" );
		if( l != null ) {
			lang = l;
		}
	}

}