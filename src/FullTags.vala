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

  private SList<FullTag> _tags;
  private bool           _modified = false;

  public signal void changed();

  // Default constructor
  public FullTags() {
    _tags = new SList<FullTag>();
    load();
  }

  // Returns the number of tags in this list.
  public int size() {
    return( (int)_tags.length() );
  }

  // Returns the tag at the given position in the list.
  public FullTag get_tag( int pos ) {
    return( _tags.nth_data( pos ) );
  }

  // XML file which stores that full list of tags
  private string xml_file() {
    return( Utils.user_location( "tags.xml" ) );
  }

  // Returns the list of tags which match the given match string.
  public bool get_matches( Array<string> matches, string match_str ) {
    matches.remove_range( 0, matches.length );
    _tags.foreach((tag) => {
      if( tag.name.contains( match_str ) ) {
        matches.append_val( tag.name );
      }
    });
    return( matches.length > 0 );
  }

  // Adds the given tag (it it currently does not exist), adjusts the count
  // and sorts the tags in alphabetical order
  public void add_tag( string tag_name, int note_id ) {
    var tag = new FullTag( tag_name );
    CompareFunc<FullTag> compare = (a, b) => {
      return( strcmp( a.name, b.name ) );
    };
    unowned var match = _tags.find_custom( tag, compare );
    if( match != null ) {
    	stdout.printf( "Found match for %s, adding note_id: %d\n", tag_name, note_id );
      match.data.add_note_id( note_id );
    } else {
      tag.add_note_id( note_id );
      _tags.append( tag );
      _tags.sort( compare );
    }
    _modified = true;
    changed();
  }

  // Decrements the tag count and, if it is zero, deletes the tag
  public void delete_tag( string tag_name, int note_id ) {
    var tag = new FullTag( tag_name );  
    CompareFunc<FullTag> compare = (a, b) => {
      return( strcmp( a.name, b.name ) );
    };
    unowned var match = _tags.find_custom( tag, compare );
    if( match != null ) {
    	var match_tag = match.data;
      match_tag.remove_note_id( note_id );
      if( match_tag.count() == 0 ) {
        _tags.remove( match_tag );
      }
      _modified = true;
       changed();
    }
  }

  // Saves this information in XML format
  public void save() {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "tags" );

    root->set_prop( "version", MosaicNote.current_version );

    _tags.foreach((tag) => {
      root->add_child( tag.save() );
  	});
  
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
        _tags.append( tag );
      }
    }
    
    delete doc;
  
  }

  // Checks the version of the XML file for any structural changes and takes action
  private void check_version( string version ) {

    // Nothing to do yet

  }

}