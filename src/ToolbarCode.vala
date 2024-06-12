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

using Gtk;

public class ToolbarCode : ToolbarItem {

  private string[] _supported_langs = {};
  private DropDown _lang;
  private bool     _ignore = false;

  // Constructor
  public ToolbarCode() {

    base( NoteItemType.CODE );

    // Get the list of available languages
    populate_supported_langs();

    var label = new Label( _( "Language:" ) );

    var strlist = new StringList( _supported_langs );
    var strexpr = new PropertyExpression( typeof(StringObject), null, "string" );
    _lang = new DropDown( strlist, strexpr ) {
      enable_search = true //,
      // 4.12 feature:  search_match_mode = StringFilterMatchMode.SUBSTRING
    };

    _lang.notify["selected"].connect(() => {
      if( _ignore ) {
        _ignore = false;
        return;
      }
      if( text != null ) {
        var mgr  = GtkSource.LanguageManager.get_default();
        var lang = mgr.get_language( _supported_langs[_lang.selected] );
        var buffer = (GtkSource.Buffer)text.buffer;
        buffer.set_language( lang );
        var code_item = (item as NoteItemCode);
        if( code_item != null ) {
          code_item.lang = _supported_langs[_lang.selected];
        }
      }
    });

    append( label );
    append( _lang );

  }

  //-------------------------------------------------------------
  // Populates the _supported_langs array with the list of supported
  // language IDs.
  private void populate_supported_langs() {

    var lang_mgr = GtkSource.LanguageManager.get_default();

    foreach( var lang in lang_mgr.get_language_ids() ) {
      if( lang != "mosaic-markdown" ) {
        _supported_langs += lang;
      }
    }

  }

  // Called to update the state of the language dropdown list widget
  private void set_language( string lang ) {
    var index = 0;
    foreach( string supported_lang in _supported_langs ) {
      if( supported_lang == lang ) {
        _ignore = true;
        _lang.selected = index;
      }
      index++;
    }
  }

  protected override void text_updated() {
    var buffer = (GtkSource.Buffer)text.buffer;
    set_language( buffer.language.id );
  }

}