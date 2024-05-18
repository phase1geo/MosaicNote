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

public enum FilterTagType {
  MATCHES,
  DOES_NOT_MATCH,
  NUM;

  public string to_string() {
    switch( this ) {
      case MATCHES        :  return( "match" );
      case DOES_NOT_MATCH :  return( "no-match" );
      default             :  assert_not_reached();
    }
  }

  public static FilterTagType parse( string val ) {
    switch( val ) {
      case "match"    :  return( MATCHES );
      case "no-match" :  return( DOES_NOT_MATCH );
      default         :  assert_not_reached();
    }
  }

}

public class FilterTag : SmartFilter {

  private string        _tag;
  private FilterTagType _type;

  // Default constructor
  public FilterTag( string tag, FilterTagType type ) {
    base();
    _tag  = tag;
    _type = type;
  }

  // Constructo from XML
  public FilterTag.from_xml( Xml.Node* node ) {
    base.from_xml( node );
    load( node );
  }

  // Checks the note to see if it matches or does not match the
  // stored tag value.
  public override bool check_note( Note note ) {
    switch( _type ) {
      case FilterTagType.MATCHES        :  return( note.tags.contains_tag( _tag ) );
      case FilterTagType.DOES_NOT_MATCH :  return( !note.tags.contains_tag( _tag ) );
      default                           :  return( false );
    }
  }

  public override Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "tag" );
    node->set_prop( "tag", _tag );
    node->set_prop( "type", _type.to_string() );
    return( node );
  }

  public override void load( Xml.Node* node ) {
    var t = node->get_prop( "tag" );
    if( t != null ) {
      _tag = t;
    }
    var p = node->get_prop( "type" );
    if( p != null ) {
      _type = FilterTagType.parse( p );
    }
  }

}