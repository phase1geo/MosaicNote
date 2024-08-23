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

using Gee;

public class NoteItemMarkdown : NoteItem {

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemMarkdown( Note note ) {
		base( note, NoteItemType.MARKDOWN );
	}

  //-------------------------------------------------------------
	// Constructor from XML node
	public NoteItemMarkdown.from_xml( Note note, Xml.Node* node ) {
		base( note, NoteItemType.MARKDOWN );
		load( node );
	}

  //-------------------------------------------------------------
	// Converts the content to markdown text
	public override string to_markdown( NotebookTree? notebooks, bool pandoc ) {
    try {
      var re  = new Regex( """\[\[(.*?)\]\]""" );
      var str = re.replace_eval( content, content.length, 0, 0, (match, result) => {
        var link = match.fetch( 1 );
        var note = notebooks.find_note_by_title( link );
        var uri  = "mosaicnote://show-note?id=%d".printf( note.id );
        result.append( "[%s](%s)".printf( link, uri ) );
        return( false );
      });
      return( str );
    } catch( RegexError e ) {}
		return( content );
	}

  //-------------------------------------------------------------
  // Exports the given note item.
  public override string export( NotebookTree? notebooks, string assets_dir ) {
    try {
      var re  = new Regex( """\[(.*?)\]\s*\((.*?)\)""" );
      var md  = to_markdown( notebooks, false );
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

}