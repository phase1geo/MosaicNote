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

using Gtk;

public class NoteItemPaneCode : NoteItemPane {

  private static Array<string>? _supported_langs = null;

  private Label          _h2_label;
  private GtkSource.View _text;

  public NoteItemCode code_item {
    get {
      return( (NoteItemCode)item );
    }
  }

  //-------------------------------------------------------------
	// Default constructor
	public NoteItemPaneCode( MainWindow win, NoteItem item, SpellChecker? spell ) {
    if( _supported_langs == null ) {
      var lang_mgr = GtkSource.LanguageManager.get_default();
      _supported_langs = new Array<string>();
      foreach( var lang in lang_mgr.get_language_ids() ) {
        if( lang != "mosaic-markdown" ) {
          _supported_langs.append_val( lang );
        }
      }
    }
    base( win, item, spell );
  }

  //-------------------------------------------------------------
  // Returns the text associated with this panel item
  public override GtkSource.View? get_text() {
    return( _text );
  }

  //-------------------------------------------------------------
  // Grabs the focus of the note item at the specified position.
  public override void grab_item_focus( TextCursorPlacement placement ) {
    place_cursor( _text, placement );
    _text.grab_focus();
  }

  //-------------------------------------------------------------
  // Returns any CSS data that this pane requires
  public static string get_css_data() {
    var font_size = MosaicNote.settings.get_int( "editor-font-size" );
    var css_data = """
      .code-text {
        font-family: monospace;
        font-size: %dpt;
      }
    """.printf( font_size );
    return( css_data );
  }

  //-------------------------------------------------------------
  // Retrieves the index of the stored item's language.
  private int get_lang_index() {
    for( int i=0; i<_supported_langs.length; i++ ) {
      var lang = _supported_langs.index( i );
      if( lang == code_item.lang ) {
        return( i );
      }
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Adds an optional description entry field for the code.
  protected override Widget create_header1() {

    var default_text = _( "Description (Optional)" );

    var entry = new EditableLabel( (code_item.description == "") ? default_text : code_item.description ) {
      halign = Align.FILL,
      hexpand = true
    };

    entry.notify["editing"].connect(() => {
      if( !entry.editing ) {
        var text = (entry.text == default_text) ? "" : entry.text;
        if( code_item.description != text ) {
          win.undo.add_item( new UndoItemDescChange( item, code_item.description ) );
          code_item.description = text;
          _h2_label.label = Utils.make_title( text );
        }
      }
    });

    var strlist = new StringList( _supported_langs.data );
    var strexpr = new PropertyExpression( typeof(StringObject), null, "string" );
    var lang_dd = new DropDown( strlist, strexpr ) {
      enable_search     = true,
      search_match_mode = StringFilterMatchMode.SUBSTRING,
      selected          = get_lang_index()
    };

    lang_dd.notify["selected"].connect(() => {
      var mgr  = GtkSource.LanguageManager.get_default();
      var lang = mgr.get_language( _supported_langs.index( lang_dd.selected ) );
      var buffer = (GtkSource.Buffer)_text.buffer;
      buffer.set_language( lang );
      code_item.lang = _supported_langs.index( lang_dd.selected );
    });

    save.connect(() => {
      var text = (entry.text == default_text) ? "" : entry.text;
      if( code_item.description != text ) {
        win.undo.add_item( new UndoItemDescChange( item, code_item.description ) );
        code_item.description = text;
        _h2_label.label = Utils.make_title( text );
      }
    });

    code_item.notify["description"].connect(() => {
      var text = (code_item.description == "") ? default_text : code_item.description;
      if( entry.text != text ) {
        entry.text = text;
        _h2_label.label = Utils.make_title( text );
      }
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( entry );
    box.append( lang_dd );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates header bar shown when the pane is not selected
  protected override Widget? create_header2() {

    _h2_label = new Label( Utils.make_title( code_item.description ) ) {
      use_markup = true,
      halign = Align.FILL,
      justify = Justification.CENTER
    };

    return( _h2_label );

  }

  //-------------------------------------------------------------
  // Creates the pane for this code item.
  protected override Widget create_pane() {

    _text = create_text( code_item.lang );
    var buffer = (GtkSource.Buffer)_text.buffer;

    var scheme_mgr = new GtkSource.StyleSchemeManager();
    var scheme     = scheme_mgr.get_scheme( MosaicNote.settings.get_string( "default-theme" ) );
    buffer.style_scheme = scheme;

    _text.add_css_class( "code-text" );

    MosaicNote.settings.changed["default-theme"].connect(() => {
      buffer.style_scheme = scheme_mgr.get_scheme( MosaicNote.settings.get_string( "default-theme" ) );
    });

    // Add the handle events
    handle_key_events( _text );

    return( _text );

  }

}