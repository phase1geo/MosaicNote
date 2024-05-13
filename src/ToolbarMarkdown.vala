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

public class ToolbarMarkdown : ToolbarItem {

  public GtkSource.View? view { get; set; default = null; }

  // Constructor
  public ToolbarMarkdown() {

    base( NoteItemType.MARKDOWN );

    var bold = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Bold" ), "<Control>b" ),
      child = create_label( " <b>B</b> " )
    };
    bold.clicked.connect( insert_bold );
    append( bold );

    var italics = new Button() {
      has_frame = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Italic" ), "<Control>i" ),
      child = create_label( " <i>I</i> " )
    };
    italics.clicked.connect( insert_italics );
    append( italics );

    var strike = new Button() {
      has_frame = false,
      tooltip_text = _( "Strikethrough" ),
      child = create_label( " <s>S</s>" )
    };
    strike.clicked.connect( insert_strike );
    append( strike );

    var code = new Button() {
      has_frame = false,
      tooltip_text = _( "Code Block" ),
      child = create_label( "{ }" )
    };
    code.clicked.connect( insert_code );
    append( code );

    var link = new Button.from_icon_name( "insert-link-symbolic" ) {
      has_frame = false,
      tooltip_text = _( "Add Link" )
    };
    link.clicked.connect( insert_link );
    append( link );

  }

  private Widget create_label( string markup ) {
    var lbl = new Label( "<span size=\"large\">" + markup + "</span>" ) {
      use_markup = true
    };
    return( lbl );
  }

  private void insert_bold() {
    MarkdownFuncs.insert_bold_text( view, view.buffer );
    view.grab_focus();
  }

  private void insert_italics() {
    MarkdownFuncs.insert_italicize_text( view, view.buffer );
    view.grab_focus();
  }

  private void insert_strike() {
    MarkdownFuncs.insert_strikethrough_text( view, view.buffer );
    view.grab_focus();
  }

  private void insert_code() {
    MarkdownFuncs.insert_code_text( view, view.buffer );
    view.grab_focus();
  }

  private void insert_link() {
    MarkdownFuncs.insert_link_text( view, view.buffer );
    view.grab_focus();
  }

}