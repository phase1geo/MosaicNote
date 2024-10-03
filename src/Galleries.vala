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

public class Galleries {

  private Array<Gallery> _galleries;

  public signal void changed();

  //-------------------------------------------------------------
  // Default constructor
  public Galleries( NotebookTree notebooks ) {
    _galleries = new Array<Gallery>();
    load( notebooks );
  }

  //-------------------------------------------------------------
  // Called when one of the galleries is modified.
  public void set_modified() {
    changed();
  }

  //-------------------------------------------------------------
  // Returns the number of galleries stored here.
  public int size() {
    return( (int)_galleries.length );
  }

  //-------------------------------------------------------------
  // Returns the gallery at the specified index.
  public Gallery get_gallery( int index ) {
    return( _galleries.index( index ) );
  }

  //-------------------------------------------------------------
  // Called when a note is deleted.  Updates the galleries.
  public void remove_note( Note note ) {
    for( int i=0; i<_galleries.length; i++ ) {
      _galleries.index( i ).remove_note( note );
    }
  }

  //-------------------------------------------------------------
  // Called when a note item is deleted.  Updates the galleries.
  public void remove_note_item( NoteItem item ) {
    for( int i=0; i<_galleries.length; i++ ) {
      _galleries.index( i ).remove_note_item( item );
    }
  }

  //-------------------------------------------------------------
  // Called when a note is saved.  Updates the galleries.
  public void handle_note( Note note ) {
    for( int i=0; i<_galleries.length; i++ ) {
      _galleries.index( i ).handle_note( note );
    }
  }

  //-------------------------------------------------------------
  // Returns the full filename of the notebooks XML file.
  private string xml_file() {
    return( Utils.user_location( "galleries.xml" ) );
  }

  //-------------------------------------------------------------
  // Saves the gallery information to an XML formatted file.
  public void save() {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "galleries" );

    root->set_prop( "version", MosaicNote.current_version );

    for( int i=0; i<_galleries.length; i++ ) {
      root->add_child( _galleries.index( i ).save() );
    }
  
    doc->set_root_element( root );
    doc->save_format_file( xml_file(), 1 );
  
    delete doc;

  }

  //-------------------------------------------------------------
  // Creates the default galleries
  private void create_default_galleries( NotebookTree notebooks ) {
    for( int i=0; i<NoteItemType.NUM; i++ ) {
      var item_type = (NoteItemType)i;
      if( item_type.has_gallery() ) {
        var gallery = new Gallery( notebooks, item_type );
        gallery.changed.connect( set_modified );
        _galleries.append_val( gallery );
      }
    }
  }

  //-------------------------------------------------------------
  // Loads the gallery information from an XML-formatted file.
  public void load( NotebookTree notebooks ) {

    var doc = Xml.Parser.read_file( xml_file(), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      create_default_galleries( notebooks );
      return;
    }

    Xml.Node* root = doc->get_root_element();
    
    var verson = root->get_prop( "version" );
    if( verson != null ) {
      check_version( verson );
    }

    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "gallery") ) {
        var gallery = new Gallery.from_xml( notebooks, it );
        gallery.changed.connect( set_modified );
        _galleries.append_val( gallery );
      }
    }
    
    delete doc;

  }

  //-------------------------------------------------------------
  // Handles any changes between XML file versions.
  private void check_version( string version ) {

    // Nothing to do yet

  }

}