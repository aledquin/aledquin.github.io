INSTALLATION

Unpack the distribution whereever you want it and add a link
to nagelfar.tcl from any directory in your path.

The syntax database in the distribution may not be right for your system.
Look in the file syntaxdb.tcl, or in the About window to see the platform
and version it is for.  Read syntaxdatabases.txt for more information on
how to generate your own.


REQUIREMENTS

Nagelfar requires Tcl 8.5 or higher.
If you do not have 8.5, you can run Nagelfar as a Starkit
using a 8.5 based Tclkit. http://wiki.tcl.tk/tclkit

Generally it is good to run Nagelfar in a Tcl at least as new the script
is targeted for.


USAGE

This tool is both a command line tool and a GUI tool.

Typical usage:
nagelfar.tcl <tcl-file>

For a usage summary:
nagelfar.tcl -h

Multiple files can be checked in one command. In that case the tool
will remember procedures from previous files when checking a file.


GUI

If you start it without arguments or with -gui, you get GUI mode,
provided that Tk can be found.

Nagelfar supports drag&drop if TkDnd is available.

The GUI lists database files and lets you select one to use.

The other list shows files to check. With multiple files all are checked
in the same way as with multiple files on a command line.
You can reorder files with shift-up/down keys, and remove them with delete.

By doubleclicking on an error the file and line is viewed in a simple
editor. You can edit and save the file.


FEEDBACK

Bugs and suggestions can be added to the trackers at:
http://nagelfar.sourceforge.net/

You can also mail peter.spjuth@gmail.com
(I also accept beer and teddybears, or just a note saying you use the
tool so I get encouraged to work on it.)


GENERATE HEADERS

You can generate a header file to help checking multiple files.

nagelfar.tcl -header <out-file> <file1> <file2>

You can then check file1 and get it to recognise procs from file2 too:

nagelfar.tcl <out-file> <file1>


PACKAGE DATABASES

A few syntax databases are included in the packagedb directory, and
more can be added by a user to automatically handle packages.

For example, if "package require snit" is encountered in the checked code,
Nagelfar looks for the file "snitdb.tcl" in the packagedb directly.
The file is always lower case and and "::" in the package names is replaced
with "_".


TODO

The database in syntaxbuild is far from complete when it comes to subcommands.
Handle widgets -command options, bind code and other callbacks
Handle e.g. -textvariable
Handle namespaces and qualified vars better
Everything marked FIXA
Tidy up code structure. Things are getting messy.
Handle namespace import if the namespace is known e.g. from a package db.
Maybe places where a constant list is expected (e.g. foreach {a b} ...)
should be able to recognise [list a b] as a constant list.

Recognise the idiom [list cmd arg arg] as code.
Recognise the idiom [set $var] for double dereferencing.
Option to enforce switch --.
Option to enforce not using "then".

Make a GUI to help working with the database builder.  It should
be possible to add packages that should be included in the db.
