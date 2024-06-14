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

public enum TimeType {
  MINUTE,
  HOUR,
  DAY,
  WEEK,
  MONTH,
  YEAR,
  NUM;

  public string to_string() {
    switch( this ) {
      case MINUTE :  return( "minute" );
      case HOUR   :  return( "hour" );
      case DAY    :  return( "day" );
      case WEEK   :  return( "week" );
      case MONTH  :  return( "month" );
      case YEAR   :  return( "year" );
      default     :  assert_not_reached();
    }
  }

  public string label() {
    switch( this ) {
      case MINUTE :  return( "minute(s)" );
      case HOUR   :  return( "hour(s)" );
      case DAY    :  return( "day(s)" );
      case WEEK   :  return( "week(s)" );
      case MONTH  :  return( "month(s)" );
      case YEAR   :  return( "year(s)" );
      default     :  assert_not_reached();
    }
  }

  public static TimeType parse( string val ) {
    switch( val ) {
      case "minute" :  return( MINUTE );
      case "hour"   :  return( HOUR );
      case "day"    :  return( DAY );
      case "week"   :  return( WEEK );
      case "month"  :  return( MONTH );
      case "year"   :  return( YEAR );
      default       :  assert_not_reached();
    }
  }

  public DateTime from_date( DateTime now, int num ) {
    switch( this ) {
      case MINUTE :  return( now.add_minutes( num ) );
      case HOUR   :  return( now.add_hours( num ) );
      case DAY    :  return( now.add_days( num ) );
      case WEEK   :  return( now.add_days( (num * 7) ) );
      case MONTH  :  return( now.add_months( num ) );
      case YEAR   :  return( now.add_years( num ) );
      default     :  return( now );
    }
  }

}

public enum DateMatchType {
  IS,
  IS_NOT,
  BEFORE,
  AFTER,
  LAST,
  LAST_NOT,
  NEXT,
  NEXT_NOT,
  NUM;

  public string to_string() {
    switch( this ) {
      case IS       :  return( "is" );
      case IS_NOT   :  return( "is-not" );
      case BEFORE   :  return( "before" );
      case AFTER    :  return( "after" );
      case LAST     :  return( "last" );
      case LAST_NOT :  return( "last-not" );
      case NEXT     :  return( "next" );
      case NEXT_NOT :  return( "next-not" );
      default       :  assert_not_reached();
    }
  }

  public string label() {
    switch( this ) {
      case IS       :  return( "is" );
      case IS_NOT   :  return( "is not" );
      case BEFORE   :  return( "before" );
      case AFTER    :  return( "after" );
      case LAST     :  return( "in the last" );
      case LAST_NOT :  return( "not in the last" );
      case NEXT     :  return( "in the next" );
      case NEXT_NOT :  return( "not in the next" );
      default       :  assert_not_reached();
    }
  }

  public static DateMatchType parse( string val ) {
    switch( val ) {
      case "is"       :  return( IS );
      case "is-not"   :  return( IS_NOT );
      case "before"   :  return( BEFORE );
      case "after"    :  return( AFTER );
      case "last"     :  return( LAST );
      case "last-not" :  return( LAST_NOT );
      case "next"     :  return( NEXT );
      case "next-not" :  return( NEXT_NOT );
      default         :  assert_not_reached();
    }
  }

  public bool is_absolute() {
    return( (this == IS) || (this == IS_NOT) || (this == BEFORE) || (this == AFTER) );
  }

  public bool is_relative() {
    return( (this == LAST) || (this == LAST_NOT) || (this == NEXT) || (this == NEXT_NOT) );
  }

  private bool is_matches( DateTime act, DateTime exp ) {
    return( act.compare( exp ) == 0 );
  }

  private bool before_matches( DateTime act, DateTime exp ) {
    return( act.compare( exp ) < 0 );
  }

  private bool after_matches( DateTime act, DateTime exp ) {
    return( act.compare( exp ) > 0 );
  }

  private bool last_matches( DateTime act, int num, TimeType amount ) {
    var now  = new DateTime.now();
    var then = amount.from_date( now, (0 - num) );
    return( (act.compare( now ) != 1) && (act.compare( then ) != -1) );
  }

  private bool next_matches( DateTime act, int num, TimeType amount ) {
    var now  = new DateTime.now();
    var then = amount.from_date( now, num );
    return( (act.compare( now ) != -1) && (act.compare( then ) != 1) );
  }

  public bool absolute_matches( DateTime act, DateTime exp ) {
    switch( this ) {
      case IS     :  return( is_matches( act, exp ) );
      case IS_NOT :  return( !is_matches( act, exp ) );
      case BEFORE :  return( before_matches( act, exp ) );
      case AFTER  :  return( after_matches( act, exp ) );
      default     :  return( false );
    }
  }

  public bool relative_matches( DateTime act, int num, TimeType amount ) {
    switch( this ) {
      case LAST     :  return( last_matches( act, num, amount ) );
      case LAST_NOT :  return( !last_matches( act, num, amount ) );
      case NEXT     :  return( next_matches( act, num, amount ) );
      case NEXT_NOT :  return( !next_matches( act, num, amount ) );
      default       :  return( false );
    }
  }

}

//-------------------------------------------------------------
// Base filter class that is used for date-based filtering.
public class SmartDateFilter : SmartFilter {

  private DateMatchType _match_type = DateMatchType.IS;
  private TimeType      _time_type  = TimeType.DAY;
  private int           _num        = 0;
  private DateTime      _exp        = new DateTime.now_local();

  //-------------------------------------------------------------
  // Default constructor
  public SmartDateFilter() {}

  //-------------------------------------------------------------
  // Constructor from XML format
  public SmartDateFilter.from_xml( Xml.Node* node ) {
    load_from_node( node );
  }

  //-------------------------------------------------------------
  // Returns whether or not the given DateTime matches the
  // current criteria.
  public bool check_date( DateTime date ) {

    if( _match_type.is_absolute() ) {
      return( _match_type.absolute_matches( date, _exp ) );
    } else if( _match_type.is_relative() ) {
      return( _match_type.relative_matches( date, _num, _time_type ) );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Returns the contents of this filter as a string.
  public override string to_string() {
    return( "" );
  }

  //-------------------------------------------------------------
  // Saves the filter setup in XML format
  protected void save_to_node( Xml.Node* node ) {

    node->set_prop( "match-type", _match_type.to_string() );

    if( _match_type.is_absolute() ) {
      node->set_prop( "date-time", _exp.format_iso8601() );
    } else {
      node->set_prop( "num", _num.to_string() );
      node->set_prop( "amount", _time_type.to_string() );
    }

  }

  //-------------------------------------------------------------
  // Loads the filter content from XML format
  public void load_from_node( Xml.Node* node ) {

    var t = node->get_prop( "match-type" );
    if( t != null ) {
      _match_type = DateMatchType.parse( t );
    }

    var dt = node->get_prop( "date-time" );
    if( dt != null ) {
      _exp = new DateTime.from_iso8601( dt, null );
    }

    var n = node->get_prop( "num" );
    if( n != null ) {
      _num = int.parse( n );
    }

    var amt = node->get_prop( "amount" );
    if( amt != null ) {
      _time_type = TimeType.parse( amt );
    }

  }

}