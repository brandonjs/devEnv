" Document Header Creator for vim
" Copyright (c) 2003 Vidyut Luther
" A GnomeDoc function document headers looks like this:
" /**
"  * func_name:
"  * @arg1: 
"  *
"  * [Description]
"  *
"  * Return value:
"  **/

if has ("user_commands")

func! CreateHeader()

	" Shortcuts for editing the text:
	let txtBOL = "norm! o"
	let txtEOL = ""
	" Depending on some VI variables that I do not know you might have
	" to change these...
	"	txtCommentHead	Start the comment block
	"	txtComment1	Line used for first comment line
	"	txtCommentn	Line used for following comment lines
	"	txtCommentTail	End of the comment block
	if b:current_syntax == "php"
		" ... PHP doesn't either 
		let txtCommentHead = "/**"
		let txtComment1 = " * "
		let txtCommentn = "* "
		let txtCommentTail = "**/"
	else
		" Most other languages use # for comments
		" NOTE: This is just an extra option. The code is written for
		"	C files, nothing else!
		let txtCommentHead = "##"
		let txtComment1 = "# "
		let txtCommentn = "# "
		let txtCommentTail = "##"
	endif

	let LineToEndOn = line(".")

	" Go to the beginning of the file
	"exe "norm! [["
	let lastline = line (".") - 1

	" Find the previous blank line and assume the function starts there
	exe "norm! {"
	let firstline = line (".") + 1

	let i = firstline
	let name = ""
	while i <= lastline
		" Remove "//" comments directly
		let name = name . " " . substitute (getline (i), '\(.*\)\/\/.*', '\1', "")
		let i = i + 1
	endwhile

	" First some things to make it more easy for us:
	" tab -> space && space+ -> space
	let name = substitute (name, '\t', ' ', "")
	let name = substitute (name, '  *', ' ', "")

	" Now we have to split DECL in three parts:
	" \(return type\)\(funcname\)\(parameters\)

    
	  exe txtBOL . txtCommentHead . txtEOL
    exe txtBOL . txtCommentn . "+----------------------------------------------------------------------+" . txtEOL
	exe txtBOL . txtCommentn . "| $Workfile: $										                   |" . txtEOL
    exe txtBOL . txtCommentn . "+----------------------------------------------------------------------+" . txtEOL
    exe txtBOL . txtCommentn . "| $Revision: $ (PHP 4)                                                 |" . txtEOL
    exe txtBOL . txtCommentn . "+----------------------------------------------------------------------+" . txtEOL
	exe txtBOL . txtCommentn . "| Copyright (c) 2002-2004                                              |" . txtEOL
    exe txtBOL . txtCommentn . "+----------------------------------------------------------------------+" . txtEOL
    exe txtBOL . txtCommentn . "| Author: Yann Larrivee <ylarrivee@phpquebec.com.com>                  |" . txtEOL
    exe txtBOL . txtCommentn . "+----------------------------------------------------------------------+" . txtEOL
    exe txtBOL . txtCommentn . txtEOL
    exe txtBOL . txtCommentn . "$Header: $"
    let LineToEndOn = line(".")

	" Close the comment block.
	exe txtBOL . txtCommentTail . txtEOL

	" Let the editor go to the right line so the user can start editing
	" right away.
	return "norm! " . LineToEndOn . "G$"
endfunc

endif " user_commands
