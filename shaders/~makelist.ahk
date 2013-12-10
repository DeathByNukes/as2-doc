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
StringTrimRight, list, list, 1 ; remove final newline
Sort, list
output = <dl class="shadersList">`n
Loop, Parse, list, `n
{
	StringSplit, split, A_LoopField, `r
	name := split1
	file := split2
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
  <dt><dfn id="shader-%name%">"%name%"</dfn> <a href="#shader-%name%">#</a></dt>
  <dd>%text%</dd>

	)
	output .= text
}
FileDelete ~shaderlist.html
FileAppend, %output%</dl>, ~shaderlist.html
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
repeatStr(string, times)
{
	VarSetCapacity(out, times * StrLen(string))
	Loop %times%
		out .= string
	return out
}