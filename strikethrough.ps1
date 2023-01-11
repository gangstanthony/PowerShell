# https://stackoverflow.com/questions/74863423/add-a-strikethrough-a-c-sharp-string

function strikethrough ($text, [switch]$clip) {
    try {
    add-type @"
namespace MyNamespace
{
    public static class MyProgram
    {
		public static string StrikeThrough (this string value)
        {
            var sb = new System.Text.StringBuilder();
            foreach (var character in value)
                sb.Append(character).Append('\u0336');

            return sb.ToString();
        }
	}
}
"@
    } catch {}

    [MyNamespace.MyProgram]::StrikeThrough($text)

    if ($clip) {
        [MyNamespace.MyProgram]::StrikeThrough($text) | Set-Clipboard
    }
}
