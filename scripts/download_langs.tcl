#!/usr/bin/tclsh

# Description:
# This script evaluates the GtkSource.LanguageManager supported languages along with the list of
# available pandoc languages.  Any languages that cannot be found will be searched for in the KDE
# syntax-highlight GitHub project and available XML files will be copied into the MosaicNote
# data/pandoc-langs directory and the associated files will be automatically added to the
# data/com.github.phase1geo.mosaic-note.gresource.xml file

if {[file tail [pwd]] ne "MosaicNote"} {
  puts "ERROR:  Script must be run from the MosaicNote project directory"
  exit 1
}

set syntax_dir       [file join / tmp syntax-highlighting data syntax]
set pandoc_langs_dir [file join data pandoc-langs]

# Clone the KDE syntax-highlighting project to /tmp space
if {![file exists $syntax_dir]} {
  puts -nonewline "Cloning KDE syntax-highlighting projects... "
  exec -ignorestderr git clone https://github.com/KDE/syntax-highlighting.git [file join / tmp syntax-highlighting]
  puts "DONE!"
}

# Get the list of supported GtkSource.LanguageManager languages
array set gtk_langs [list]
foreach lang [glob -directory [file join / usr share gtksourceview-5 language-specs] -tails -nocomplain *.lang] {
  set gtk_langs([file rootname $lang]) 1
}
puts "gtk: [lsort [array names gtk_langs]]"

# Get the list of supported pandoc languages
foreach lang [split [exec -ignorestderr pandoc --list-highlight-languages] \n] {
  array unset gtk_langs $lang
}
puts "gtk_langs: [lsort [array names gtk_langs]]"

foreach lang_file [lsort [glob -directory $syntax_dir -tails *.xml]] {
  set lang [file rootname $lang_file]
  if {[info exists gtk_langs($lang)]} {
    puts "Copying $lang_file to $pandoc_langs_dir"
    file copy -force [file join $syntax_dir $lang_file] $pandoc_langs_dir
    array unset gtk_langs $lang
  }
}
puts "Unsupported langs: [lsort [array names gtk_langs]]"
