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

public class SmartLogicFilter : SmartFilter {

  protected Array<SmartFilter> filters;

  //-------------------------------------------------------------
  // Default constructor
  public SmartLogicFilter() {
    filters = new Array<SmartFilter>();
  }

  //-------------------------------------------------------------
  // Constructor from XML format
  public SmartLogicFilter.from_xml( Xml.Node* node ) {}

  //-------------------------------------------------------------
  // Returns the number of stored smart filters.
  public int size() {
    return( (int)filters.length );
  }

  //-------------------------------------------------------------
  // Returns the smart filter at the given index.
  public SmartFilter get_filter( int index ) {
    return( filters.index( index ) );
  }

  //-------------------------------------------------------------
  // Adds the specified smart filter to the list of filters managed
  // by this logic filter.
  public virtual void add_filter( SmartFilter filter ) {
    filters.append_val( filter );
  }

  //-------------------------------------------------------------
  // Removes the smart filter at the given index.
  public virtual void remove_filter( int index ) {
    filters.remove_index( index );
  }

  //-------------------------------------------------------------
  // Returns true if the note matches the filter.
  public override bool check_note( Note note ) {
    return( false );
  }

  //-------------------------------------------------------------
  // Helper utility for derived logic filters.
  protected string to_string_with_connector( string connector ) {
    string[] parts = {};
    for( int i=0; i<filters.length; i++ ) {
      parts += filters.index( i ).to_string();
    }
    return( "(" + string.joinv( (" " + connector + " "), parts ) + ")" );
  }

  //-------------------------------------------------------------
  // Saves the filter setup in XML format
  protected virtual void save_to_node( Xml.Node* node ) {
    for( int i=0; i<filters.length; i++ ) {
      node->add_child( filters.index( i ).save() );
    }
  }

  //-------------------------------------------------------------
  // Loads the filter content from XML format
  public virtual void load_from_node( Xml.Node* node ) {
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        SmartFilter? filter = null;
        switch( it->name ) {
          case "created"   :  filter = new FilterCreated.from_xml( it );   break;
          case "favorite"  :  filter = new FilterFavorite.from_xml( it );  break;
          case "item"      :  filter = new FilterItem.from_xml( it );      break;
          case "item-text" :  filter = new FilterItemText.from_xml( it );  break;
          case "locked"    :  filter = new FilterLocked.from_xml( it );    break;
          case "notebook"  :  filter = new FilterNotebook.from_xml( it );  break;
          case "tag"       :  filter = new FilterTag.from_xml( it );       break;
          case "title"     :  filter = new FilterTitle.from_xml( it );     break;
          case "updated"   :  filter = new FilterUpdated.from_xml( it );   break;
          case "viewed"    :  filter = new FilterViewed.from_xml( it );    break;
          case "logic-and" :  filter = new FilterAnd.from_xml( it );       break;
          case "logic-or"  :  filter = new FilterOr.from_xml( it );        break;
          case "logic-not" :  filter = new FilterNot.from_xml( it );       break;
        }
        if( filter != null ) {
          filters.append_val( filter );
        }
      }
    }
  }

}