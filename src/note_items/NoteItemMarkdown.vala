/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

using Gee;

public class NoteItemMarkdown : NoteItem {

  private static Regex? _header_re = null;

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemMarkdown( NoteItemRow row ) {
		base( row, NoteItemType.MARKDOWN );
    make_header_re();
	}

  //-------------------------------------------------------------
	// Constructor from XML node
	public NoteItemMarkdown.from_xml( NoteItemRow row, Xml.Node* node ) {
		base( row, NoteItemType.MARKDOWN );
    make_header_re();
		load( node );
	}

  //-------------------------------------------------------------
  // Creates the header regular expression if it does not exist.
  private void make_header_re() {
    if( _header_re == null ) {
      try {
        _header_re = new Regex( """^(#{1,6})\s+(.*)(\s+\1)?$""" );
        stdout.printf( "Figured out header_re\n" );
      } catch( RegexError e ) {
        stdout.printf( "Error: %s\n", e.message );
        assert_not_reached();
      }
    }
  }

  //-------------------------------------------------------------
  // Provides the title for the pandoc output.
  public override string pandoc_title() {
    MatchInfo match;
    var lines = content.split( "\n" );
    if( _header_re.match( lines[0], 0, out match ) ) {
      return( match.fetch( 2 ) );
    } else if( (lines.length >= 2) && (lines[0].strip() != "") && lines[0].get_char( 0 ).isalpha() && (lines[1].has_prefix( "-" ) || lines[1].has_prefix( "=" )) ) {
      return( lines[0].strip() );
    } else {
      return( base.pandoc_title() );
    }
  }

  //-------------------------------------------------------------
	// Converts the content to markdown text
	public override string to_markdown( NotebookTree? notebooks, bool include_footnotes, bool pandoc, bool presenter ) {
    try {
      var markdown = content;
      if( presenter ) {
        var lines = content.split( "\n" );
        var curr  = 0;
        if( _header_re.match( lines[0] ) ) {
          curr = 1;
        } else if( (lines.length >= 2) && (lines[0].strip() != "") && lines[0].get_char( 0 ).isalpha() && (lines[1].has_prefix( "-" ) || lines[1].has_prefix( "=" )) ) {
          curr = 2;
        }
        while( (curr < lines.length) && (lines[curr].strip() == "") ) {
          curr++;
        }
        markdown = string.joinv( "\n", lines[curr:lines.length] );
      }
      var nl_re = new Regex( """\[\[(.*?)\]\]""" );
      var str = nl_re.replace_eval( markdown, markdown.length, 0, 0, (match, result) => {
        var link = match.fetch( 1 );
        var note = notebooks.find_note_by_title( link );
        var uri  = "mosaicnote://show-note?id=%d".printf( note.id );
        result.append( "[%s](%s)".printf( link, uri ) );
        return( false );
      });
      if( include_footnotes ) {
        MatchInfo matched;
        var fn_re     = new Regex( """\[\^(.*?)\]""" );
        var start     = 0;
        var footnotes = get_note().footnotes;
        while( fn_re.match_full( markdown, -1, start, 0, out matched ) ) {
          int s, e;
          var id = matched.fetch( 1 );
          matched.fetch_pos( 0, out s, out e );
          str += "\n\n[^%s]: %s".printf( id, (footnotes.has_key( id ) ? footnotes.get( id ) : "") );
          start = e;
        }
      }
      return( str );
    } catch( RegexError e ) {}
		return( content );
	}

  //-------------------------------------------------------------
  // Exports the given note item.
  public override string export( NotebookTree? notebooks, bool include_footnotes, string assets_dir ) {
    try {
      var re  = new Regex( """\[(.*?)\]\s*\((.*?)\)""" );
      var md  = to_markdown( notebooks, include_footnotes, false, false );
      var str = re.replace_eval( md, md.length, 0, 0, (match, result) => {
        var asset = copy_asset( assets_dir, match.fetch( 2 ) );
        result.append( "[" + match.fetch( 1 ) + "](" + asset + ")" ); 
        return( false );
      });
      return( str );
    } catch( RegexError e ) {}
    return( content );
  }

  //-------------------------------------------------------------
  // Retrieves all of the note links in the text.
  public override void get_note_links( HashSet<string> note_titles ) {
    try {
      MatchInfo matches;
      var re    = new Regex("\\[\\[(.*?)\\]\\]");
      var start = 0;
      if( re.match_full( content, -1, start, 0, out matches ) ) {
        int start_pos, end_pos;
        matches.fetch_pos( 1, out start_pos, out end_pos );
        note_titles.add( content.slice( start_pos, end_pos ) );
        start = end_pos;
      }
    } catch( RegexError e ) {}
  }

  //-------------------------------------------------------------
  // Converts a raw header from Markdown into a header link by
  // converting all alpha-numeric values to their lowercase value,
  // converting spaces to dashes, and removing all other characters.
  private string convert_raw_header( string header ) {
    var new_header = "";
    for( int i=0; i<header.length; i++ ) {
      if( header.valid_char( i ) ) {
        var ch = header.get_char( i );
        if( ch.isalnum() ) {
          new_header += ch.to_string().down();
        } else if( ch.isspace() ) {
          new_header += "-";
        }
      }
    }
    return( new_header );
  }

  //-------------------------------------------------------------
  // Returns true if the contents of the Markdown text contains
  // any hashed header that matches the link header.
  private bool contains_hash_header( string header ) {
    try {
      MatchInfo matched;
      var re = new Regex( """^#{1,6}\s(.*)$""" );
      foreach( var line in content.split( "\n" ) ) {
        if( re.match( line, 0, out matched ) ) {
          var raw_header = matched.fetch( 1 );
          if( convert_raw_header( raw_header ) == header ) {
            return( true );
          }
        }
      }
    } catch( RegexError e ) {}
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if we contain an underlined header that matches
  // the given link header.
  private bool contains_underline_header( string header ) {
    try {
      MatchInfo matched;
      var re   = new Regex( """^(-+|=+)\s*$""" );
      var last = "";
      foreach( var line in content.split( "\n" ) ) {
        if( re.match( line ) && (last != "") ) {
          if( convert_raw_header( last ) == header ) {
            return( true );
          }
        }
        last = line;
      }
    } catch( RegexError e ) {}
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if this item contains a Markdown header that
  // matches the given header link.
  public override bool contains_header( string header ) {
    return( contains_hash_header( header ) || contains_underline_header( header ) );
  }

}
