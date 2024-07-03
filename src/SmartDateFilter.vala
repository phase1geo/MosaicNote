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

  public string? search_string() {
    switch( this ) {
      case DAY    :  return( _( "day" ) );
      case WEEK   :  return( _( "week" ) );
      case MONTH  :  return( _( "month" ) );
      case YEAR   :  return( _( "year" ) );
      default     :  return( null );
    }
  }

  public string? search_detail() {
    switch( this ) {
      case DAY   :  return( _( "Include notes with a date in the past N days" ) );
      case WEEK  :  return( _( "Include notes with a date in the past N weeks" ) );
      case MONTH :  return( _( "Include notes with a date in the past N months" ) );
      case YEAR  :  return( _( "Include notes with a date in the past N years" ) );
      default    :  return( null );
    }
  }

  public string label() {
    switch( this ) {
      case MINUTE :  return( _( "minute(s)" ) );
      case HOUR   :  return( _( "hour(s)" ) );
      case DAY    :  return( _( "day(s)" ) );
      case WEEK   :  return( _( "week(s)" ) );
      case MONTH  :  return( _( "month(s)" ) );
      case YEAR   :  return( _( "year(s)" ) );
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

  public static TimeType? parse_full( string val ) {
    var down = val.down();
    if( _( "days" ).has_prefix( down ) ) {
      return( DAY );
    } else if( _( "weeks" ).has_prefix( down ) ) {
      return( WEEK );
    } else if( _( "months" ).has_prefix( down ) ) {
      return( MONTH );
    } else if( _( "years" ).has_prefix( down ) ) {
      return( YEAR );
    } else {
      return( null );
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
  BEFORE_NOT,
  AFTER,
  AFTER_NOT,
  BETWEEN,
  BETWEEN_NOT,
  LAST,
  LAST_NOT,
  NUM;

  public string to_string() {
    switch( this ) {
      case IS          :  return( "is" );
      case IS_NOT      :  return( "is-not" );
      case BEFORE      :  return( "before" );
      case BEFORE_NOT  :  return( "before-not" );
      case AFTER       :  return( "after" );
      case AFTER_NOT   :  return( "after-not" );
      case BETWEEN     :  return( "between" );
      case BETWEEN_NOT :  return( "between-not" );
      case LAST        :  return( "last" );
      case LAST_NOT    :  return( "last-not" );
      default          :  assert_not_reached();
    }
  }

  public string? search_string() {
    switch( this ) {
      case IS      :  return( "is" );
      case BEFORE  :  return( "before" );
      case AFTER   :  return( "after" );
      case BETWEEN :  return( "between" );
      case LAST    :  return( "last" );
      default      :  return( null );
    }
  }

  public string? search_detail() {
    switch( this ) {
      case IS      :  return( _( "Include notes that are on a specified date." ) );
      case BEFORE  :  return( _( "Include notes before a specified date." ) );
      case AFTER   :  return( _( "Include notes after a specified date." ) );
      case BETWEEN :  return( _( "Include notes between two specified dates." ) );
      case LAST    :  return( _( "Include notes with a date in the last specified time period." ) );
      default      :  return( null );
    }
  }

  public string label() {
    switch( this ) {
      case IS          :  return( _( "is" ) );
      case IS_NOT      :  return( _( "is not" ) );
      case BEFORE      :  return( _( "before" ) );
      case BEFORE_NOT  :  return( _( "not before" ) );
      case AFTER       :  return( _( "after" ) );
      case AFTER_NOT   :  return( _( "not after" ) );
      case BETWEEN     :  return( _( "between" ) );
      case BETWEEN_NOT :  return( _( "not between" ) );
      case LAST        :  return( _( "in the last" ) );
      case LAST_NOT    :  return( _( "not in the last" ) );
      default          :  assert_not_reached();
    }
  }

  public static DateMatchType parse( string val ) {
    switch( val ) {
      case "is"          :  return( IS );
      case "is-not"      :  return( IS_NOT );
      case "before"      :  return( BEFORE );
      case "before-not"  :  return( BEFORE_NOT );
      case "after"       :  return( AFTER );
      case "after-not"   :  return( AFTER_NOT );
      case "between"     :  return( BETWEEN );
      case "between-not" :  return( BETWEEN_NOT );
      case "last"        :  return( LAST );
      case "last-not"    :  return( LAST_NOT );
      default            :  assert_not_reached();
    }
  }

  public bool is_absolute() {
    return( (this == IS)      || (this == IS_NOT)     ||
            (this == BEFORE)  || (this == BEFORE_NOT) ||
            (this == AFTER)   || (this == AFTER_NOT)  ||
            (this == BETWEEN) || (this == BETWEEN_NOT) );
  }

  public bool is_relative() {
    return( (this == LAST) || (this == LAST_NOT) );
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

  private bool between_matches( DateTime act, DateTime first, DateTime second ) {
    return( (act.compare( first ) >= 0) && (act.compare( second ) <= 0) );
  }

  private bool last_matches( DateTime act, int num, TimeType amount ) {
    var now  = new DateTime.now();
    var then = amount.from_date( now, (0 - num) );
    return( (act.compare( now ) != 1) && (act.compare( then ) != -1) );
  }

  public bool absolute_matches( DateTime act, DateTime first, DateTime second ) {
    switch( this ) {
      case IS          :  return( is_matches( act, first ) );
      case IS_NOT      :  return( !is_matches( act, first ) );
      case BEFORE      :  return( before_matches( act, first ) );
      case BEFORE_NOT  :  return( !before_matches( act, first ) );
      case AFTER       :  return( after_matches( act, first ) );
      case AFTER_NOT   :  return( !after_matches( act, first ) );
      case BETWEEN     :  return( between_matches( act, first, second ) );
      case BETWEEN_NOT :  return( !between_matches( act, first, second ) );
      default          :  return( false );
    }
  }

  public bool relative_matches( DateTime act, int num, TimeType amount ) {
    switch( this ) {
      case LAST     :  return( last_matches( act, num, amount ) );
      case LAST_NOT :  return( !last_matches( act, num, amount ) );
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
  private DateTime      _first      = new DateTime.now_local();
  private DateTime      _second     = new DateTime.now_local();

  //-------------------------------------------------------------
  // Default constructor
  public SmartDateFilter() {}

  //-------------------------------------------------------------
  // Constructor for absolute dates
  public SmartDateFilter.absolute( DateMatchType match_type, DateTime first, DateTime? second = null ) {
    _match_type = match_type;
    _first      = first;
    if( second != null ) {
      _second = second;
    }
  }

  //-------------------------------------------------------------
  // Constructor for relative dates
  public SmartDateFilter.relative( DateMatchType match_type, int num, TimeType time_type ) {
    _match_type = match_type;
    _num        = num;
    _time_type  = time_type;
  }

  //-------------------------------------------------------------
  // Constructor from XML format
  public SmartDateFilter.from_xml( Xml.Node* node ) {
    load_from_node( node );
  }

  //-------------------------------------------------------------
  // Copies the contents of this filter to the given filter.
  protected void copy_to( SmartDateFilter filter ) {
    filter._match_type = _match_type;
    filter._time_type  = _time_type;
    filter._num        = _num;
    filter._first      = _first.to_local();
    filter._second     = _second.to_local();
  }

  //-------------------------------------------------------------
  // Returns whether or not the given DateTime matches the
  // current criteria.
  public bool check_date( DateTime date ) {

    var date_only = new DateTime.local( date.get_year(), date.get_month(), date.get_day_of_month(), 0, 0, 0.0 );

    if( _match_type.is_absolute() ) {
      return( _match_type.absolute_matches( date_only, _first, _second ) );
    } else if( _match_type.is_relative() ) {
      return( _match_type.relative_matches( date_only, _num, _time_type ) );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Returns the contents of this filter as a string.
  public override string to_string() {

    var first_str  = _first.format( "%Y/%m/%d" );
    var second_str = _second.format( "%Y/%m/%d" );

    switch( _match_type ) {
      case IS          :  return( "is[%s]".printf( first_str ) );
      case IS_NOT      :  return( "!is[%s]".printf( first_str ) );
      case BEFORE      :  return( "before[%s]".printf( first_str ) );
      case BEFORE_NOT  :  return( "!before[%s]".printf( first_str ) );
      case AFTER       :  return( "after[%s]".printf( first_str ) );
      case AFTER_NOT   :  return( "!after[%s]".printf( first_str ) );
      case BETWEEN     :  return( "between[%s-%s]".printf( first_str, second_str ) );
      case BETWEEN_NOT :  return( "!between[%s-%s]".printf( first_str, second_str ) );
      case LAST        :  return( "last[%d%s]".printf( _num, _time_type.to_string() ) );
      case LAST_NOT    :  return( "!last[%d%s]".printf( _num, _time_type.to_string() ) );
      default          :  return( "" );
    }

  }

  //-------------------------------------------------------------
  // Saves the filter setup in XML format
  protected void save_to_node( Xml.Node* node ) {

    node->set_prop( "match-type", _match_type.to_string() );

    if( _match_type.is_absolute() ) {
      node->set_prop( "first-date", _first.format_iso8601() );
      node->set_prop( "second-date", _second.format_iso8601() );
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

    var fd = node->get_prop( "first-date" );
    if( fd != null ) {
      _first = new DateTime.from_iso8601( fd, null );
    }

    var sd = node->get_prop( "second-date" );
    if( sd != null ) {
      _second = new DateTime.from_iso8601( sd, null );
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