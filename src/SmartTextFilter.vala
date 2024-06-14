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

public enum TextMatchType {
  CONTAINS,
  REGEXP,
  NUM;

  public string to_string() {
    switch( this ) {
      case CONTAINS :  return( "contains" );
      case REGEXP   :  return( "regexp" );
      default       :  assert_not_reached();
    }
  }

  public string label() {
    switch( this ) {
      case CONTAINS :  return( _( "Contains" ) );
      case REGEXP   :  return( _( "Regular Expression" ) );
      default       :  assert_not_reached();
    }
  }

  public static TextMatchType parse( string val ) {
    switch( val ) {
      case "contains" :  return( CONTAINS );
      case "regexp"   :  return( REGEXP );
      default         :  assert_not_reached();
    }
  }

}

//-------------------------------------------------------------
// SmartFilter that specifically has options for matching text.
public class SmartTextFilter : SmartFilter {

  public TextMatchType match_type { get; set; default = TextMatchType.CONTAINS; }
  public string        pattern    { get; set; default = ""; }

  //-------------------------------------------------------------
  // Default constructor
  public SmartTextFilter( TextMatchType match_type, string pattern ) {
    this.match_type = match_type;
    this.pattern    = pattern;
  }

  //-------------------------------------------------------------
  // Constructor from XML format
  public SmartTextFilter.from_xml( Xml.Node* node ) {
    base.from_xml( node );
    load_from_node( node );
  }

  //-------------------------------------------------------------
  // Returns whether the given text matches this text search filter.
  protected bool check_text( string text ) {
    if( match_type == TextMatchType.CONTAINS ) {
      return( text.contains( pattern ) );
    } else {
      return( Regex.match_simple( pattern, text ) );
    }
  }

  //-------------------------------------------------------------
  // Returns the contents of this text filter as a string.
  public override string to_string() {
    return( (match_type == TextMatchType.REGEXP) ? "re[%s]".printf( pattern ) : pattern );
  }

  //-------------------------------------------------------------
  // Saves the filter setup in XML format
  public void save_to_node( Xml.Node* node ) {
    node->set_prop( "match-type", match_type.to_string() );
    node->set_prop( "pattern",    pattern );
  }

  //-------------------------------------------------------------
  // Loads the filter content from XML format
  public void load_from_node( Xml.Node* node ) {

    var m = node->get_prop( "match-type" );
    if( m != null ) {
      match_type = TextMatchType.parse( m );
    }

    var p = node->get_prop( "pattern" );
    if( p != null ) {
      pattern = p;
    }

  }

}