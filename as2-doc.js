$.ajaxSetup({
	async: false
});

function writeNavigation(max_header_level, show_all_headers)
{
	if(typeof(max_header_level) === 'undefined') max_header_level = 6;
	if(typeof(show_all_headers) === 'undefined') show_all_headers = true;
	
	document.write('<nav><ul id=navigation></ul></nav>');
	$(document).ready(function()
	{
		var contents = [ [] ];
		
		function addEntry(string) {
			contents[contents.length - 1].push(string);
		}
		function addElement() {
			//console.log(this.tagName);
			if (this.id != '')
				addEntry('<li><a href="#' + this.id + '">' + $(this).text() + '</a></li>');
			else if (show_all_headers)
				addEntry('<li>' + $(this).text() + '</li>');
		}
		function push() {
			contents.push([]);
		}
		function pop()
		{
			var entries = contents.pop();
			if (entries.length < 1)
				return; // discard empty sections
			addEntry('<ul>\n' + entries.join('\n') + '\n</ul>');
		}
		
		var o;
		var header_level = 1;
		push(); // this section represents everything before the first h1 (usually empty)
		$("body > :header, body > dl").each(function()
		{
			o = $(this);
			if (this.tagName.toUpperCase() === 'DL')
			{
				var dl_ids = o.find("dt[id]")
				if (dl_ids.length == 0)
					dl_ids = o.find("dfn[id]")
				dl_ids.each(addElement);
				return;
			}
			// :header
			var new_level = this.tagName.charAt(1);
			if (new_level > header_level)
			{
				if (new_level > max_header_level)
					return;
				++header_level;
				while (new_level > header_level)
				{
					push();
					++header_level;
				}
			}
			else
			{
				while (new_level < header_level)
				{
					pop();
					--header_level;
				}
				pop();
			}
			addElement.call(this);
			push();
		});
		
		while (contents.length > 1) { pop(); }
		$("#navigation").html(contents[0].join('\n'));
	});
}

function writeTypes()
{
	document.write('<div id="types-container">Loading...</div>');
	$('#types-container').load('shared-types.html #template > *', function() {
		$('#types-container > *').unwrap();
	});
	console.log($('#types-container').text());
}
function writeScriptFunctions()
{
	document.write('<div id="script-functions-container">Loading...</div>');
	$('#script-functions-container').load('shared-script-functions.html #template > *', function() {
		$('#script-functions-container > *').unwrap();
	});
	console.log($('#script-functions-container').text());
}

function writeAbout_Doc()
{
	document.write('<p>This is a part of my <a href="index.html">Audiosurf 2 scripting documentation</a>.</p>');
}

function SafeTags(str) {
	return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
}

/*
<!--
formatting regex:
^([^ \[]*) 
<a href="#type-\1">\1</a> 
^([^ <]*)\[\]
<a href="#type-\1">\1</a><a href="#type-array">[]</a>
-->
*/

function formatTypes(types_page)
{
	if(typeof(types_page) !== 'string') types_page = "";
	var types = /\b(bool|string|float|double|int|table|address|color|vector3|vector2|materialcolor|material|scale|transform|transform2|mesh|gameobject|globalname)\b/g;
	var type_format = '<a href="#type-$1">$1</a>';
	
	function eachNode()
	{
		o = $(this);
		if (this.nodeType === 3) // TEXT_NODE
		{
			var text = SafeTags(this.data);
			text = text.replace(types, type_format);
			o.replaceWith(text);
		}
		else if (this.nodeType === 1 && this.tagName !== 'A') // ELEMENT_NODE
			o.contents().each(eachNode);
	}
	
	$(document).ready(function()
	{
		$("code.doc").contents().each(eachNode);
	});
}

function writeBitwiseRow(n, zero, one, bits)
{
	if (!zero && !one)
	{
		zero = "<td></td>";
		one = "<td>O</td>";
	}
	if (!bits)
		bits = 32;
	var out = new Array(bits);
	for (var i = 0; i < bits; ++i)
		out[i] = ((n >> i) & 1) == 0 ? zero : one;
	document.write(out.join(""));
}
function writeBitwiseHeader(open, close, bits, offset)
{
	if (!open && !close)
	{
		open = "<th>";
		close = "</th>";
	}
	if (!bits)
		bits = 32;
	if (!offset)
		offset = 0;
	var out = new Array(bits*3);
	for (var i = 0; i < bits; ++i)
	{
		out[i*3+0] = open;
		out[i*3+1] = (i+offset).toString();
		out[i*3+2] = close;
	}
	document.write(out.join(""));
}
