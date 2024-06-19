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

public class SmartParser {

  private NotebookTree           _notebooks;
  private List<SmartLogicFilter> _stack;

  //-------------------------------------------------------------
  // Default constructor
  public SmartParser( NotebookTree notebooks ) {
    _notebooks = notebooks;
    _stack = new List<SmartLogicFilter>();
  }

  //-------------------------------------------------------------
  // Parses the given search string and constructs a smart filter
  // 
  public bool parse( string search_str ) {

    var and_filter = new FilterAnd();
    var in_double  = false;
    var in_single  = false;
    var skip_char  = false;
    var token      = "";

    _stack.append( and_filter );

    for( int i=0; i<search_str.length; i++ ) {
      if( search_str.valid_char( i ) ) {
        var ch = search_str.get_char( i );
        if( skip_char ) {
          token += ch.to_string();
          skip_char = false;
        } else {
          switch( ch ) {
            case ' ' :
              if( !in_double && !in_single ) {
                parse_token( token );
                token = "";
              } else {
                token += " ";
              }
              break;
            case '"'  :
              if( !in_single ) {
                in_double = !in_double;
              } else {
                token += "\"";
              }
              break;
            case '\'' :
              if( !in_double ) {
                in_single = !in_single;
              } else {
                token += "'";
              }
              break;
            case '('  :
              if( !in_single && !in_double ) {
                push_filter( false );
              } else {
                token += "(";
              }
              break;
            case ')'  :
              if( !in_single && !in_double ) {
                parse_token( token );
                token = "";
                pop_filter();
              } else {
                token += ")";
              }
              break;
            case '!'  :
              if( !in_single && !in_double && (token == "") ) {
                push_filter( true );
              } else {
                token += "!";
              }
              break;
            case '\\' :  skip_char = true;  token += ch.to_string();  break;
            default   :  token += ch.to_string();  break;
          }
        }
      }
    }

    stdout.printf( "token: %s\n", token );

    if( token != "" ) {
      parse_token( token );
    }

    pop_all();

    stdout.printf( "----------------------------------\n" );
    stdout.printf( "FILTER: %s\n", and_filter.to_string() );

    return( (_stack.length() == 1) && !in_double && !in_single && !skip_char );

  }

  //-------------------------------------------------------------
  // Populates the given smart notebook with the matching notes
  // within the list of available notebooks.
  public void populate_smart_notebook( SmartNotebook notebook ) {
    unowned var last = _stack.last();
    if( (last != null) && ((last.data as SmartLogicFilter) != null) ) {
      notebook.filter = (SmartLogicFilter)last.data;
      _notebooks.populate_smart_notebook( notebook );
      _stack.remove( last.data );
    }
  }

  //-------------------------------------------------------------
  // Pushes an AND logic filter onto the stack.  If push_not is
  // set, we will add a NOT logic filter to the stack followed
  // by an AND filter
  private void push_filter( bool push_not ) {
    var and_filter = new FilterAnd();
    if( push_not ) {
      var not_filter = new FilterNot();
      _stack.append( not_filter );
    }
    _stack.append( and_filter );
  }

  //-------------------------------------------------------------
  // Pops the top of the stack and adds it to the new top of stack.
  private void pop_filter() {
    unowned var last = _stack.last();
    if( last != null ) {
      var pop_filter = (last.data as SmartLogicFilter);
      if( pop_filter != null ) {
        _stack.remove( last.data );
        if( (((pop_filter as FilterAnd) != null) || ((pop_filter as FilterOr) != null)) && (pop_filter.size() == 1) ) {
          add_filter_to_stack_top( pop_filter.get_filter( 0 ) );
        } else {
          add_filter_to_stack_top( pop_filter );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Pops all of the stack items until the stack is a length of 1.
  private void pop_all() {
    while( _stack.length() > 1 ) {
      pop_filter();
    }
  }

  //-------------------------------------------------------------
  // Parses the given search token and adds it to the top of the stack.
  private bool parse_token( string token ) {

    if( token.get_char( 0 ) == '#' ) {
      var tag = token.substring( token.index_of_nth_char( 1 ) );
      return( parse_tag( tag ) );
    }

    if( token.get_char( 0 ) == '@' ) {
      var date = token.substring( token.index_of_nth_char( 1 ) );
      return( parse_date( "created", date ) );
    }

    if( (token.down() == "and") || (token == "&") || (token == "&&") ) {
      // An AND should always be at the top of the stack
      return( true );
    }

    if( (token.down() == "or") || (token == "|") || (token == "||") ) {
      // AND operations take precedence over OR operations, so if we encounter an OR
      // and the top of the stack is not an OR filter, we need to create the OR, place
      // the stack top inside of the OR and make the OR the current top
      unowned var last = _stack.last();
      if( (last != null) && ((last.data as FilterOr) == null) ) {
        var or_filter  = new FilterOr();
        var and_filter = new FilterAnd();
        var top_filter = last.data;
        _stack.remove( last.data );
        or_filter.add_filter( (FilterAnd)top_filter );
        _stack.append( or_filter );
        _stack.append( and_filter );
      }
      return( true );
    }

    var parts = token.split( ":" );
    if( parts.length == 2 ) {
      switch( parts[0].down() ) {
        case "favorite" :  return( parse_bool( "favorite", parts[1] ) );
        case "locked"   :  return( parse_bool( "locked", parts[1] ) );
        case "created"  :  return( parse_date( "created", parts[1] ) );
        case "updated"  :  return( parse_date( "updated", parts[1] ) );
        case "viewed"   :  return( parse_date( "viewed", parts[1] ) );
        case "notebook" :  return( parse_notebook( parts[1] ) );
        case "tag"      :  return( parse_tag( parts[1] ) );
        case "title"    :  return( parse_text( "title", parts[1] ) );
        case "block"    :  return( parse_block( parts[1] ) );
        case "content"  :  return( parse_text( "content", parts[1] ) );
      }
    }

    if( parts.length == 1 ) {
      return( parse_text( "any", token ) );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Adds the given filter to the top of the stack
  private bool add_filter_to_stack_top( SmartFilter filter ) {
    unowned var last = _stack.last();
    if( last != null ) {
      var last_filter = (last.data as SmartLogicFilter);
      last_filter.add_filter( filter );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the tag string, creates the tag filter and adds it
  // to the top of the stack.
  //
  // Examples:
  //   tag:!foobar
  //   tag:barfoo
  private bool parse_tag( string tag ) {
    if( tag.get_char( 0 ) == '!' ) {
      var filter = new FilterTag( tag.substring( tag.index_of_nth_char( 1 ) ), FilterTagType.DOES_NOT_MATCH );
      add_filter_to_stack_top( filter );
    } else {
      var filter = new FilterTag( tag, FilterTagType.MATCHES );
      add_filter_to_stack_top( filter );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the date value.
  //
  // Examples:
  //   created:is[YYYY/MM/DD]
  //   created:!YYYY/MM/DD  (same as is)
  //   created:between[YYYY/MM/DD-YYYY/MM/DD]
  //   created:YYYY/MM/DD-YYYY/MM/DD
  //   created:before[YYYY/MM/DD]
  //   created:<YYYY/MM/DD  (same as before)
  //   created:after[YYYY/MM/DD]
  //   created:>YYYY/MM/DD  (same as after)
  //   created:last[3days]
  //   created:!last[1y]
  private bool parse_date( string filter_type, string date ) {
    var str = date;
    var not = false;
    if( str.get_char( 0 ) == '!' ) {
      not = true;
      str = str.substring( str.index_of_nth_char( 1 ) );
    }
    if( str.has_suffix( "]" ) ) {
      str = str.slice( 0, str.index_of_nth_char( str.char_count() - 1 ) );
      if( str.has_prefix( "is[" ) ) {
        str = str.substring( str.index_of_nth_char( 3 ) );
        return( parse_absolute_date( filter_type, (not ? DateMatchType.IS_NOT : DateMatchType.IS), str ) );
      } else if( str.has_prefix( "between[" ) ) {
        str = str.substring( str.index_of_nth_char( 8 ) );
        var dates = str.split( "-" );
        if( dates.length == 2 ) {
          return( parse_absolute_date( filter_type, DateMatchType.BETWEEN, dates[0], dates[1] ) );
        }
      } else if( date.has_prefix( "before[" ) ) {
        str = str.substring( str.index_of_nth_char( 7 ) );
        return( parse_absolute_date( filter_type, DateMatchType.BEFORE, str ) );
      } else if( date.has_prefix( "after[" ) ) {
        str = str.substring( str.index_of_nth_char( 6 ) );
        return( parse_absolute_date( filter_type, DateMatchType.AFTER, str ) );
      } else if( date.has_prefix( "last[" ) ) {
        str = str.substring( str.index_of_nth_char( 5 ) );
        return( parse_relative_date( filter_type, (not ? DateMatchType.LAST_NOT : DateMatchType.LAST), str ) );
      }
    } else if( date.has_prefix( "<" ) ) {
      str = str.substring( str.index_of_nth_char( 1 ) );
      return( parse_absolute_date( filter_type, DateMatchType.BEFORE, str ) );
    } else if( date.has_prefix( ">" ) ) {
      return( parse_absolute_date( filter_type, DateMatchType.AFTER, str ) );
    } else {
      var dates = str.split( "-" );
      if( dates.length == 2 ) {
        return( parse_absolute_date( filter_type, DateMatchType.BETWEEN, dates[0], dates[1] ) );
      } else {
        stdout.printf( "not: %s\n", not.to_string() );
        return( parse_absolute_date( filter_type, (not ? DateMatchType.IS_NOT : DateMatchType.IS), str ) );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses a string in the form of YYYY/MM/DD.  Returns the
  // associated DateTime structure if the string can be parsed;
  // otherwise, returns null to indicate that the date string
  // is invalid.
  private DateTime? parse_absolute_date_format( string? date ) {
    if( date != null ) {
      var parts = date.split( "/" );
      if( (parts.length == 3) && (parts[0].length == 4) && (parts[1].length == 2) && (parts[2].length == 2) ) {
        var year  = int.parse( parts[0] );
        var month = int.parse( parts[1] );
        var day   = int.parse( parts[2] );
        if( (year != 0) && (month != 0) && (day != 0) ) {
          var dt = new DateTime.local( year, month, day, 0, 0, 0.0 );
          return( dt );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Handle a date that should be treated as an absolute date.  We
  // will create and add up the filter(s) to the stack.
  private bool parse_absolute_date( string filter_type, DateMatchType match_type, string first, string? second = null ) {
    SmartDateFilter? filter = null;
    var first_date  = parse_absolute_date_format( first );
    var second_date = parse_absolute_date_format( second );
    if( (match_type == DateMatchType.BETWEEN) && (second_date == null) ) {
      return( false );
    }
    if( first_date != null ) {
      switch( filter_type ) {
        case "created" :  filter = new FilterCreated.absolute( match_type, first_date, second_date );  break;
        case "updated" :  filter = new FilterUpdated.absolute( match_type, first_date, second_date );  break;
        case "viewed"  :  filter = new FilterViewed.absolute( match_type, first_date, second_date );   break;
      }
    }
    if( filter != null ) {
      add_filter_to_stack_top( filter );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Handle a date that should be treated as a relative date to
  // the current date.  We will create and add up the filter(s)
  // to the stack.
  private bool parse_relative_date( string filter_type, DateMatchType match_type, string period ) {
    SmartDateFilter? filter    = null;
    TimeType?        time_type = null;
    var num = -1;
    var str = "";
    period.down().scanf( "%d%s", &num, str );
    stdout.printf( "period: %s, num: %d, str: %s\n", period.down(), num, str );
    if( str != "" ) {
      time_type = TimeType.parse_full( str );
      stdout.printf( "filter_type: %s, time_type: %s\n", filter_type, time_type.to_string() );
    }
    if( (num > 0) && (time_type != null) ) {
      switch( filter_type ) {
        case "created" :  filter = new FilterCreated.relative( match_type, num, time_type );  break;
        case "updated" :  filter = new FilterUpdated.relative( match_type, num, time_type );  break;
        case "viewed"  :  filter = new FilterViewed.relative( match_type, num, time_type );   break;
      }
    }
    if( filter != null ) {
      add_filter_to_stack_top( filter );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses a boolean value.
  //
  // Examples:
  //   favorite:(true|false|0|1)
  private bool parse_bool( string filter_type, string rest ) {
    var val = true;
    if( (rest.down() == "true") || (rest == "1") ) {
      val = true;
    } else if( (rest.down() == "false") || (rest == "0") ) {
      val = false;
    } else {
      return( false );
    }

    SmartFilter? filter = null;
    switch( filter_type ) {
      case "favorite" :  filter = new FilterFavorite( val );  break;
      case "locked"   :  filter = new FilterLocked( val );    break;
    }
    if( filter != null ) {
      add_filter_to_stack_top( filter );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the given notebook string value.
  //
  // Examples:
  //   notebook:<name>
  //   notebook:<path>/<of>/<notebook>
  private bool parse_notebook( string name ) {
    Notebook? nb = null;
    if( name.contains( "/" ) ) {
      nb = _notebooks.find_notebook_by_name( name );
    } else {
      nb = _notebooks.find_notebook_by_path( name );
    }
    if( nb != null ) {
      var filter = new FilterNotebook( nb.id );
      add_filter_to_stack_top( filter );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the given title and creates a filter for it.
  //
  // Examples:
  //   title:<string>
  //   title:re[<string>]
  private bool parse_text( string filter_type, string text ) {
    SmartFilter? filter = null;
    var pattern    = text;
    var match_type = TextMatchType.CONTAINS;
    if( text.has_prefix( "re[" ) && text.has_suffix( "]" ) ) {
      pattern    = text.slice( text.index_of_nth_char( 3 ), text.index_of_nth_char( text.char_count() - 1 ) );
      match_type = TextMatchType.REGEXP;
    }
    stdout.printf( "match_type: %s, pattern: %s, filter_type: %s\n", match_type.to_string(), pattern, filter_type );
    switch( filter_type ) {
      case "title"   :  filter = new FilterTitle( match_type, pattern );     break;
      case "content" :  filter = new FilterItemText( NoteItemType.MARKDOWN, match_type, pattern );  break;
      case "any"     :
        {
          var title_filter   = new FilterTitle( match_type, pattern );
          var content_filter = new FilterItemText( NoteItemType.MARKDOWN, match_type, pattern );
          var or_filter = new FilterOr();
          or_filter.add_filter( title_filter );
          or_filter.add_filter( content_filter );
          filter = or_filter;
        }
        break;
    }
    if( filter_type != null ) {
      add_filter_to_stack_top( filter );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Parses the give block type.
  //
  // Examples:
  //   block:(markdown|code|image|uml)
  //   block:!code
  private bool parse_block( string block ) {
    if( block.has_prefix( "!" ) ) {
      var item_type = NoteItemType.parse( block.substring( block.index_of_nth_char( 1 ) ) );
      if( item_type != NoteItemType.NUM ) {
        var item_filter = new FilterItem( item_type );
        var not_filter  = new FilterNot();
        not_filter.add_filter( item_filter );
        add_filter_to_stack_top( not_filter );
        return( true );
      }
    } else {
      var item_type = NoteItemType.parse( block );
      if( item_type != NoteItemType.NUM ) {
        var filter = new FilterItem( item_type );
        add_filter_to_stack_top( filter );
        return( true );
      }
    }
    return( false );
  }

}