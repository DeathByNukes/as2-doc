#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1 ; gotta go fast

list =
Loop, *.shader
{
	Loop, Read, %A_LoopFileFullPath%
	{
		shader := RegExReplace(A_LoopReadLine, "^\s*Shader\s+""([^""]*)"" {$", "$1")
		if strlen(A_LoopReadLine) == strlen(shader)
			throw "not a shader?`n" A_LoopReadLine
		if shader =
		{
			SplitPath, A_LoopFileFullPath,,,, shader
			shader .= " (blank name)"
		}
		list .= shader . "`r" . A_LoopFileFullPath . "`n"
		break
	}
}
FileRemoveDir, ~renamed, 1
FileCreateDir, ~renamed
StringTrimRight, list, list, 1 ; remove final newline
Sort, list
output = <dl class="shadersList codeDefs">`n
Loop, Parse, list, `n
{
	StringSplit, split, A_LoopField, `r
	name := split1
	file := split2
	output2 .= file "`t" name "`n"
	FileRead, text, %file%

	; get the Properties { ... } section
	props := RegExReplace(text, "s)^.*?`n\s*Properties\s+{(.*?)`n\s*}.*$", "$1", change_count)
	props := trim(props, " `t`n")
	if (change_count == 0 || props == "")
		props = No properties.
	else
	{
		props := RegExReplace(props, "m`n)^\s*(.*?)\s*$", "$1") ; strip whitespace from the ends of each line
		; mark the property names/types and tabify
		IfInString, props, [
			props := RegExReplace(props, "m`n)^(?:(\[.*?\]) )?(\S+) (\(""[^""]*"",) (.+)\) (= )", "$1 `t<strong>$2</strong> `t$3 `t<span class=type>$4</span>`t) $5")
		else
			props := RegExReplace(props, "m`n)^(\[.*?\] )?(\S+) (\(""[^""]*"",) (.+)\) (= )", "$1<strong>$2</strong> `t$3 `t<span class=type>$4</span>`t) $5")
		props := fixTabs(props)
	}

	highlights =
	highlights_indent := 1024
	Loop, Parse, text, `n
	{
		line := RegExReplace(A_LoopField, "^(\s*)(SubShader|Pass|Name|ZTest|Cull|Tags|Blend|BlendOp|ColorMask|ZWrite|UsePass|GrabPass|Offset|Fallback)\b(.*?)(?:\s*\{\s*)?$", "$1<strong>$2</strong>$3", highlight_found)
		if (highlight_found == 0)
			continue
		if InStr(line, ";", true)
			throw "Line contains semicolon. Selection needs improvement?`n" line
		indent := strlen(line) - strlen(ltrim(line))
		if (indent < highlights_indent)
			highlights_indent := indent
		highlights .= (highlights == "" ? "" : "`n") line
	}
	if highlights_indent > 0
		highlights := RegExReplace(highlights, "m`n)^[ `t]{" highlights_indent "}")

	text =
	(
<dt id="shader-%name%"><dfn>%name%</dfn> <a href="#shader-%name%">#</a></dt>
<dd>
<pre><code>%props%</code></pre>
<pre><code>%highlights%</code></pre>
</dd>

	)
	output .= (A_Index == 1 ? "" : "`n`n") text

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
