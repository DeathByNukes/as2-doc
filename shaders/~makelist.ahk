#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1 ; gotta go fast

list =
Loop, *.shader
{
	Loop, Read, %A_LoopFileFullPath%
	{
		list .= RegExReplace(A_LoopReadLine, "^Shader ""([^""]+)"" {$", "$1") . "`r" . A_LoopFileFullPath . "`n"
		break
	}
}
FileRemoveDir, ~renamed, 1
FileCreateDir, ~renamed
StringTrimRight, list, list, 1 ; remove final newline
Sort, list
output = <dl class="shadersList">`n
Loop, Parse, list, `n
{
	StringSplit, split, A_LoopField, `r
	name := split1
	file := split2
	output2 .= file "`t" name "`n"
	FileRead, text, *m2000 %file% ; first 2000 bytes only
	text := RegExReplace(text, "s)^.*?`nProperties {`n(.*?)`n}.*$", "$1", change_count) ; get the Properties { ... } section
	if (change_count > 0)
	{
		text := RegExReplace(text, "m`n)^\s*(.*?)\s*$", "$1") ; strip whitespace from the ends of each line
		text := RegExReplace(text, "m`n)^(\S+) (\(""[^""]*"",) (.+)\) (= )", "<strong>$1</strong> `t$2 `t<span class=type>$3</span>`t) $4") ; mark the property names/types and tabify
		text := fixTabs(text)
		text = <pre><code>%text%</code></pre>
	}
	else
		text = No properties.
	text =
	(
	<dt><dfn id="shader-%name%">%name%</dfn> <a href="#shader-%name%">#</a></dt>
	<dd>%text%</dd>

	)
	output .= text

	StringReplace, name, name, /, \, 1
	name = ~renamed\%name%
	name_ren := name ".shader"
	while FileExist(name_ren)
		name_ren := name " (" (A_Index+1) ").shader"
	SplitPath, name,, dir
	if dir !=
	{
		FileCreateDir %dir%
		if ErrorLevel
			throw LastErrorException("'" dir "'`n", -1)
	}
	MakeHardlink(file, name_ren)
}
FileDelete ~shaderlist.html
FileAppend, %output%</dl>, ~shaderlist.html
FileDelete ~shaderlist.txt
FileAppend, %output2%, ~shaderlist.txt
SoundPlay *64
Sleep 250
ExitApp

; turn a tab-delimited collection of lines into a monospace table
fixTabs(string)
{
	chars := 0
	Loop, Parse, string, `n
	{
		rows := A_Index
		array_name = row%A_Index%col
		StringSplit, %array_name%, A_LoopField, %A_Tab%
		if (A_Index = 1)
		{
			cols := %array_name%0 - 1 ; the last column doesn't need spacing
			edge_col := %array_name%0
			Loop %cols%
				width%A_Index% := StrLen(%array_name%%A_Index%)
		}
		else
		{
			Loop %cols%
			{
				w := StrLen(%array_name%%A_Index%)
				if (width%A_Index% < w)
					width%A_Index% := w
			}
		}
		chars += %array_name%%edge_col%
	}
	string =
	Loop %cols%
		chars += width%A_Index% * rows
	chars += rows - 1 ; newlines
	VarSetCapacity(out, chars)
	Loop %rows%
	{
		array_name = row%A_Index%col
		if (A_Index != 1)
			out .= "`n"
		Loop %cols%
		{
			str := %array_name%%A_Index%
			out .= str . repeatStr(" ", width%A_Index% - StrLen(str))
		}
		out .= %array_name%%edge_col%
	}
	return out
}


RepeatStr(string, times)
{
	if (times < 1)
		return ""
	VarSetCapacity(out, times * StrLen(string))
	Loop %times%
		out .= string
	return out
}

LastErrorException(prefix = "", what = -2, extra = "") {
	return Exception(prefix LastErrorString(), what, extra)
}
LastErrorString(number = "")
{
	; probably x64 and unicode compatible
	if number =
		number := A_LastError

	; The importance of the IGNORE_INSERTS flag: https://blogs.msdn.com/b/oldnewthing/archive/2007/11/28/6564257.aspx
	if VarSetCapacity(string, 1024) >= 1024
	ret := DllCall("FormatMessage"
		, "UInt", 0x00001200 ; DWORD    dwFlags: FORMAT_MESSAGE_FROM_SYSTEM 0x00001000 | FORMAT_MESSAGE_IGNORE_INSERTS 0x00000200
		, "Ptr",  0          ; void*    lpSource
		, "UInt", number     ; DWORD    dwMessageId
		, "UInt", 0          ; DWORD    dwLanguageId: auto
		, "Str",  string     ; TSTR*    lpBuffer
		, "UInt", 1024       ; DWORD    nSize
		, "Ptr",  0)         ; va_list* Arguments
	
	StringReplace, string, string, `r`n, %A_Space%, All
	
	return string " (#" number ")"
}

MakeHardlink(source, dest)
{
	if !TryMakeHardlink(source, dest)
		throw LastErrorException(source " => " dest "`n", -3)
}
; If the function succeeds, the return value is nonzero.
TryMakeHardlink(source, dest)
{
	return DllCall("CreateHardLink" ; https://msdn.microsoft.com/en-us/library/aa363860(VS.85).aspx
		, "Str", dest   ; LPCTSTR lpFileName,
		, "Str", source ; LPCTSTR lpExistingFileName,
		, "Ptr", 0  )   ; LPSECURITY_ATTRIBUTES lpSecurityAttributes (Reserved; must be NULL.)
}
