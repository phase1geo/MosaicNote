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

public class FullTags {

	private Array<FullTag> _tags;
	private bool           _modified = false;

	// Default constructor
	public FullTags() {
		_tags = new Array<FullTag>();
		load();
	}

	// XML file which stores that full list of tags
	private string xml_file() {
		return( Utils.user_location( "tags.xml" ) );
	}

	public ListStore get_model() {

		var list = new ListStore( Type.OBJECT );

		list.append_val()

		return( list );
		
	}

	// Returns the list of tags which match the given match string.
	public bool get_matches( Array<string> matches, string match_str ) {
		matches.remove_range( 0, matches.length );
    for( int i=0; i<_tags.length; i++ ) {
    	if( _tags.index( i ).name.contains( str ) ) {
    		matches.append_val( _tags.index( i ).name );
    	}
    }
    return( matches.length > 0 );
	}

	// Adds the given tag (it it currently does not exist), adjusts the count
	// and sorts the tags in alphabetical order
	public void add_tag( string tag_name ) {
		uint pos;
		var tag = new FullTag( tag_name );
    if( _tags.binary_search( tag, FullTag.compare, out pos ) ) {
      _tags.index( pos ).adjust_count( 1 );
    } else {
    	_tags.append_val( tag );
    	_tags.sort( FullTag.compare );
    }
    _modified = true;
	}

	// Decrements the tag count and, if it is zero, deletes the tag
	public void delete_tag( string tag_name ) {
	  uint pos;
	  var tag = new FullTag( tag_name );	
	  if( _tags.binary_search( tag, FullTag.compare, out pos ) ) {
	  	if( _tags.index( pos ).count > 0 ) {
	  		_tags.index( pos ).adjust_count( -1 );
	  	  _modified = true;
	  	}
	  	if( _tags.index( pos ).count == 0 ) {
  	  	_tags.remove_index( pos );
	  	  _modified = true;
  	  }
	  }
	}

	// Saves this information in XML format
	public void save() {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
	  Xml.Node* root = new Xml.Node( null, "tags" );

	  root->set_prop( "version", MosaicNote.version );

	  for( uint i=0; i<_tags.length; i++ ) {
	  	var tag = _tags.index( i );
	  	root->add_child( tag.save() );
	  } 
	
	  doc->set_root_element( root );
	  doc->save_format_file( xml_file(), 1 );
	
	  delete doc;

	  _modified = false;

	}

	// Loads the contents of the full list of tags from XML format
	private void load() {

    var doc = Xml.Parser.read_file( xml_file(), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      return;
    }

    Xml.Node* root = doc->get_root_element();
    
    var verson = root->get_prop( "version" );
    if( verson != null ) {
      check_version( verson );
    }

    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tag") ) {
      	var tag = new FullTag.from_xml( it );
      	_tags.append_val( tag );
      }
    }
    
    delete doc;
	
	}

	// Checks the version of the XML file for any structural changes and takes action
	private void check_version( string version ) {

		// Nothing to do yet

	}

}