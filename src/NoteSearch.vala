/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/MosaicNote)
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

using Gdk;
using Gtk;

public delegate bool NoteSearchFunc( NoteItemPane? pane, string element, string str, Widget win );

public class SearchMatch {

  public NoteItemPane? pane  { set; get; default = null; }
  public Widget        win   { set; get; default = null; }
  public int           start { set; get; default = -1; }
  public int           end   { set; get; default = -1; }

  //-------------------------------------------------------------
  // Constructor
  public SearchMatch( NoteItemPane? p, Widget w, int s, int e ) {
    pane  = p;
    win   = w;
    start = s;
    end   = e;
  }

  public string to_string() {
    return( (pane == null) ? "none" : "start: %d, end: %d".printf( start, end ) );
  }

}

public class NoteSearch : Box {

  private NotePanel    _panel;
  private SearchEntry  _search_entry;
  private Button       _search_next;
  private Button       _search_prev;
  private Label        _search_matches;
  private SearchEntry  _replace_entry;
  private Button       _replace_current;
  private Button       _replace_all;
  private SearchMatch  _next;
  private SearchMatch  _prev;
  private int          _ignore_update;
  private Array<SearchMatch> _matches;
  private int                _match_index    = -1;
  private bool               _case_sensitive = false;

  private delegate void NoteSearchCallback( string match, int start, int end );

  public signal void close_requested();

  //-------------------------------------------------------------
  // Default constructor
  public NoteSearch( NotePanel panel ) {

    Object(
      orientation: Orientation.VERTICAL,
      spacing: 5,
      margin_start: 5,
      margin_end: 5,
      margin_top: 5,
      margin_bottom: 5
    );

    _panel = panel;

    _matches = new Array<SearchMatch>();
    _ignore_update = 0;
    _case_sensitive = MosaicNote.settings.get_boolean( "search-case-sensitive" );

    var search_box = new Box( Orientation.HORIZONTAL, 5 );
    add_search_entry( search_box );
    add_search_case( search_box );
    add_search_next( search_box );
    add_search_previous( search_box );
    add_search_matches( search_box );
    add_search_replace( search_box );

    var replace_box = new Box( Orientation.HORIZONTAL, 5 );
    add_replace_entry( replace_box );
    add_replace_current( replace_box );
    add_replace_all( replace_box );

    append( search_box );
    append( replace_box );

  }

  //-------------------------------------------------------------
  // Called whenever the search bar is displayed or hidden
  public void change_display( bool show ) {
    if( !show ) {
      _search_entry.text = "";
      search();
      _ignore_update = 2;
    } else {
      _search_entry.grab_focus();
      update_state();
      _ignore_update = 0;
    }
  }

  //-------------------------------------------------------------
  // Creates the search entry field and adds it to this box
  private void add_search_entry( Box box ) {

    _search_entry = new Gtk.SearchEntry() {
      halign = Align.FILL,
      hexpand = true,
      placeholder_text = _( "Find text…")
    };

    _search_entry.search_changed.connect( search );
    _search_entry.activate.connect( search_next );

    var key = new EventControllerKey();
    _search_entry.add_controller( key );

    key.key_pressed.connect((keyval, keycode, state) => {
      bool shift = (bool)(state & Gdk.ModifierType.SHIFT_MASK);
      switch( keyval ) {
        case Gdk.Key.Escape :
          close_requested();
          return( true );
        case Gdk.Key.Return :
          if( shift ) {
            search_previous();
          } else {
            search_next();
          }
          return( true );
        default :  return( false );
      }
    });

    box.append( _search_entry );

  }

  //-------------------------------------------------------------
  // Finds all matched text, adds matches to the _matches array,
  // and runs the callback function for each match.
  private bool find_matched_text( NoteItemPane? pane, Widget win, string pattern, string str, NoteSearchCallback callback ) {
    if( pattern != "" ) {
      var start       = str.index_of( pattern, 0 );
      var start_index = (int)_matches.length;
      while( start != -1 ) {
        _matches.append_val( new SearchMatch( pane, win, start, (start + pattern.length) ) );
        start = str.index_of( pattern, (start + pattern.length) );
      }
      for( int i=((int)_matches.length - 1); i>=start_index; i-- ) {
        callback( pattern, _matches.index( i ).start, _matches.index( i ).end );
      }
      return( start_index != _matches.length );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Helper function for search function which handles any match
  // checks.  This function is also responsible for clearing
  // highlights and adding highlights to the specified widget
  // for matched text.
  private bool search_match( NoteItemPane? pane, string element, string pattern, string str, Widget win ) {

    // Clear any matched patterns in the widget
    var label = (win as Label);
    if( label != null ) {
      label.label = str;
      label.use_markup = false;
      return(
        find_matched_text( pane, win, pattern, str, (match, start, end) => {
          label.label = label.label.splice( start, end, "<span background=\"orange\" foreground=\"black\">%s</span>".printf( match ) );
          label.use_markup = true;
        })
      );
    }

    var text = (win as TextView);
    if( text != null ) {
      TextIter start_iter, end_iter;
      text.buffer.get_start_iter( out start_iter );
      text.buffer.get_end_iter( out end_iter );
      text.buffer.remove_tag_by_name( "note-match", start_iter, end_iter );
      return(
        find_matched_text( pane, win, pattern, str, (match, start, end) => {
          text.buffer.get_iter_at_offset( out start_iter, str.slice( 0, start ).char_count() );
          text.buffer.get_iter_at_offset( out end_iter,   str.slice( 0, end ).char_count() );
          text.buffer.apply_tag_by_name( "note-match", start_iter, end_iter );
        })
      );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Performs the text search on the entire contents of the
  // current note.
  private void search() {

    _matches.remove_range( 0, _matches.length );
    _match_index = -1;

    var pattern = _search_entry.text;

    // Perform search
    _panel.do_note_search((pane, element, str, win) => {
      if( _case_sensitive ) {
        return( search_match( pane, element, pattern, str, win ) );
      } else {
        return( search_match( pane, element, pattern.down(), str.down(), win ) );
      }
    });

    // Update the UI state
    update_state();

  }

  //-------------------------------------------------------------
  // Updates the UI state
  private void update_state() {

    var is_next     = ((_match_index + 1) < _matches.length);
    var is_prev     = ((_match_index - 1) >= 0);
    var is_selected = is_match_selected();
    var found       = is_next || is_prev || is_selected;

    _search_next.set_sensitive( is_next );
    _search_prev.set_sensitive( is_prev );
    _search_matches.label = _( "%u matches" ).printf( _matches.length );
    _replace_entry.editable  = found;
    _replace_entry.can_focus = found;
    _replace_current.set_sensitive( (_replace_entry.text != "") && is_selected );
    _replace_all.set_sensitive( (_replace_entry.text != "") && found );

  }

  //-------------------------------------------------------------
  // Creates the search case-sensitivity UI.
  private void add_search_case( Box box ) {

    var btn = new ToggleButton() {
      label        = "Aa",
      has_frame    = false,
      active       = _case_sensitive,
      tooltip_text = _( "Toggle case-sensitivity" )
    };

    btn.notify["active"].connect(() => {
      _case_sensitive = btn.active;
      MosaicNote.settings.set_boolean( "search-case-sensitive", _case_sensitive );
      _search_entry.grab_focus();
      search();
    });

    box.append( btn );

  }

  //-------------------------------------------------------------
  // Creates the search next field and adds it to this box
  private void add_search_next( Box box ) {

    _search_next = new Gtk.Button.from_icon_name( "go-down-symbolic" );
    _search_next.clicked.connect( search_next );

    box.append( _search_next );

  }

  //-------------------------------------------------------------
  // Perform the search for the next text match
  private void search_next() {
    select_matched_text( _match_index + 1 );
  }

  //-------------------------------------------------------------
  // Selects the matched text
  private void select_matched_text( int index ) {

    if( (index < 0) || (index >= _matches.length) ) return;

    var match = _matches.index( index );
    var pane  = _matches.index( index ).pane;
    var win   = _matches.index( index ).win;

    if( match.win != null ) {
      var text = (match.win as TextView);
      if( text != null ) {
        TextIter start_iter, end_iter;
        var str = text.buffer.text;
        text.buffer.get_iter_at_offset( out start_iter, str.slice( 0, match.start ).char_count() );
        text.buffer.get_iter_at_offset( out end_iter,   str.slice( 0, match.end ).char_count() );
        text.buffer.select_range( end_iter, start_iter );
      }
    }

    // Set the match pane to be the current one
    if( pane != null ) {
      pane.set_as_current();
    }

    _match_index = index;

    // Update button states
    update_state();

  }

  //-------------------------------------------------------------
  // Creates the search previous field and adds it to the box
  private void add_search_previous( Box box ) {

    _search_prev = new Gtk.Button.from_icon_name( "go-up-symbolic" );
    _search_prev.clicked.connect( search_previous );

    box.append( _search_prev );

  }

  //-------------------------------------------------------------
  // Perform the search for the previous text match
  private void search_previous() {
    select_matched_text( _match_index - 1 );
  }

  //-------------------------------------------------------------
  // Creates the search match number and adds it to the box.
  private void add_search_matches( Box box ) {

    _search_matches = new Label( "" );

    box.append( _search_matches );

  }

  //-------------------------------------------------------------
  // Creates the show/hide replace button.
  private void add_search_replace( Box box ) {

    var btn = new ToggleButton() {
      icon_name = "edit-find-replace-symbolic",
      tooltip_text = _( "Show/Hide Replace Tools" )
    };

    btn.notify["active"].connect(() => {
      _replace_entry.visible   = btn.active;
      _replace_current.visible = btn.active;
      _replace_all.visible     = btn.active;
      if( !btn.active || (_search_entry.text == "") ) {
        _search_entry.grab_focus();
      } else {
        _replace_entry.grab_focus();
      }
    });

    box.append( btn );

  }

  //-------------------------------------------------------------
  // Returns true if the selected text is a matched pattern
  private bool is_match_selected() {

    if( _match_index >= 0 ) {
      var match = _matches.index( _match_index );
      if( match.win != null ) {
        var text = (match.win as TextView);
        if( text != null ) {
          TextIter selstart, selend;
          if( text.buffer.get_selection_bounds( out selstart, out selend ) ) {
            return( text.buffer.get_text( selstart, selend, false ) == _search_entry.text );
          }
        }
      }
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Adds the replace text entry field and adds it to this box
  private void add_replace_entry( Box box ) {

    _replace_entry = new Gtk.SearchEntry() {
      halign            = Align.FILL,
      hexpand           = true,
      visible           = false,
      placeholder_text  = _( "Replace with…")
    };

    var focus = new EventControllerFocus();
    _replace_entry.add_controller( focus );

    _replace_entry.search_changed.connect( replace_text_changed );

    focus.enter.connect( replace_focus_in );

    var key = new EventControllerKey();
    _search_entry.add_controller( key );

    key.key_pressed.connect((keyval, keymod, state) => {
      if( keyval == Gdk.Key.Escape ) {
        close_requested();
        return( true );
      }
      return( false );
    });

    box.append( _replace_entry );

  }

  //-------------------------------------------------------------
  // Called when the search box loses focus
  private void replace_focus_in() {
    if( !is_match_selected() ) {
      select_matched_text( _match_index + 1 );
    }
  }

  //-------------------------------------------------------------
  // Called whenever the replacement text is changed
  private void replace_text_changed() {
    update_state();
  }

  //-------------------------------------------------------------
  // Adds the replace current button and adds it to this box
  private void add_replace_current( Box box ) {

    _replace_current = new Gtk.Button.with_label( _( "Replace" ) ) {
      visible = false
    };
    _replace_current.clicked.connect( replace_current );

    box.append( _replace_current );

  }

  //-------------------------------------------------------------
  // Adds the replace all button and adds it to this box
  private void add_replace_all( Box box ) {

    _replace_all = new Gtk.Button.with_label( _( "Replace All" ) ) {
      visible = false
    };
    _replace_all.clicked.connect( replace_all );

    box.append( _replace_all );

  }

  /*
  FOOBAR
  buffer.mark_set.connect ((iter, mark) => {
      if (mark.get_name () == "insert" ||
          mark.get_name () == "selection_bound") {
  */

  //-------------------------------------------------------------
  // Replaces the text at the given match index.
  private void replace_match( int index, string new_text ) {

    var match = _matches.index( index );

    var text = (match.win as TextView);
    if( text != null ) {
      TextIter start, end;
      var start_offset = text.buffer.text.slice( 0, match.start ).char_count();
      var end_offset   = text.buffer.text.slice( 0, match.end ).char_count();
      text.buffer.get_iter_at_offset( out start, start_offset );
      text.buffer.get_iter_at_offset( out end,   end_offset );
      text.buffer.begin_user_action();
      text.buffer.delete_range( start, end );
      text.buffer.get_iter_at_offset( out start, start_offset );
      text.buffer.insert_text( ref start, new_text, new_text.length );
      text.buffer.end_user_action();
    }

  }

  //-------------------------------------------------------------
  // Performs the replacement for the currently matched text
  private void replace_current() {

    // Replace the current match
    replace_match( _match_index, _replace_entry.text );

    // Perform search again
    var index = _match_index;
    search();
    _match_index = index - 1;

    // Jump to the next match
    select_matched_text( _match_index + 1 );

  }

  //-------------------------------------------------------------
  // Performs the replacement for all text that matches the search text
  private void replace_all() {

    // Replace all of the matches
    for( int i=((int)_matches.length - 1); i>=0; i-- ) {
      replace_match( i, _replace_entry.text );
    }

    // Effectively clear the search
    search();

  }

}
