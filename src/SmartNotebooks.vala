/*
* Copyright (c) 2024 (https://github.com/phase1geo/MosaicNote)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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

public class SmartNotebooks {

  Array<SmartNotebook> _notebooks;
  bool _modified = false;

  // Default constructor
  public SmartNotebooks() {
    _notebooks = new Array<SmartNotebook>();
    load();
  }

  // Handles any changes to the given note, updating all stored
  // smart notebooks.
  public void handle_note( Note note ) {
    for( int i=0; i<_notebooks.length; i++ ) {
      _modified |= _notebooks.index( i ).handle_note( note );
    }
  }

  // Returns the path of the smart notebooks XML file
  private string xml_file() {
    return( Utils.user_location( "smart-notebooks.xml" ) );
  }

  // Saves the contents of the notebook array in XML format
  public void save() {

    if( !_modified ) return;

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "smart-notebooks" );

    root->set_prop( "version", MosaicNote.current_version );

    for( int i=0; i<_notebooks.length; i++ ) {
      root->add_child( _notebooks.index( i ).save() );
    }
  
    doc->set_root_element( root );
    doc->save_format_file( xml_file(), 1 );
  
    delete doc;

    _modified = false;

  }

  // Loads the XML data and recreates the list of smart notebooks.
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
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "smart-notebook") ) {
        var notebook = new SmartNotebook.from_xml( it );
        _notebooks.append_val( notebook );
      }
    }
    
    delete doc;
    
  }

  // The method can be used to make any changes/updates if the read version
  // is not compatible with the current application.
  private void check_version( string version ) {

    // TODO

  }

}