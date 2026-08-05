# ============================================================================
# Reusable .docx + .pdf generator — Moon Whale Media / Claude Code template
# ----------------------------------------------------------------------------
# Battle-tested 2026-06-08. Produces both formats from the SAME content array.
# Replace the $blocks section near the top, run the script, get both files.
#
# How to use:
#   1. Copy this file to a scratch location (do NOT edit the template directly)
#   2. Update the $baseName + $docsDir + the $blocks array
#   3. Run:  powershell.exe -ExecutionPolicy Bypass -NoProfile -File <copy>.ps1
#
# Block types you can put in $blocks (each renders to BOTH .docx and .pdf):
#   @{ t='title';    text='...' }            # 26pt indigo
#   @{ t='subtitle'; text='...' }            # 14pt
#   @{ t='meta';     text='...' }            # italic 9.5pt gray, ends with rule
#   @{ t='h1';       text='...' }            # 18pt indigo, top border
#   @{ t='h2';       text='...' }            # 13.5pt
#   @{ t='h3';       text='...' }            # 11.5pt
#   @{ t='p';        text='...' }            # body, supports inline markup
#   @{ t='b';        text='...' }            # bullet
#   @{ t='code';     text=@'multiline'@ }   # monospaced code block
#   @{ t='link-p';   text='Label'; url='https://...' }
#   @{ t='table';    rows=@(@('h1','h2'), @('a','b')) }  # first row = header
#
# Inline markup in text/cells:
#   **bold**            -> bold run
#   `code`              -> monospaced inline (uses backtick — escape with double `` in PS strings)
#   [text](url)         -> hyperlink
#
# Lessons baked in (DO NOT regress):
#   - Sort-Object on an array-of-pairs UNWRAPS the single-item case
#     -> scalar `if` chain for "smallest index" instead
#   - Chrome's stderr-on-success ("N bytes written") kills the script under
#     $ErrorActionPreference='Stop' -> wrapped in try/catch with EAP=Continue
#   - Write-Output CHECKPOINTs make hangs diagnosable when auto-backgrounded
#   - UTF-8 *without* BOM for everything; OOXML uses CRLF-tolerant parser
# ============================================================================

$ErrorActionPreference = 'Stop'
Write-Output "CHECKPOINT: script started"

# ----------------------------- CONFIGURE ME --------------------------------
$baseName     = 'My_Document'
$docsDir      = Join-Path $env:USERPROFILE 'Documents'
$downloadsDir = Join-Path $env:USERPROFILE 'Downloads'

# ----------------------------- CONTENT --------------------------------------
# Replace the entries below. Order matters — blocks render top to bottom.
$blocks = @()
$blocks += @{ t='title';    text='My Document Title' }
$blocks += @{ t='subtitle'; text='Subtitle goes here' }
$blocks += @{ t='meta';     text='Prepared YYYY-MM-DD for Moon Whale Media, LLC.' }
$blocks += @{ t='h1'; text='1. Section One' }
$blocks += @{ t='p';  text='Some body text with **bold** and `inline code` and a [hyperlink](https://example.com).' }
$blocks += @{ t='b';  text='A bullet item.' }
$blocks += @{ t='b';  text='Another bullet item, with **inline bold**.' }
$blocks += @{ t='code'; text=@'
// code block — preserves indentation
function example() {
  return 42;
}
'@ }
$blocks += @{ t='table'; rows=@(
  @('Header 1','Header 2','Header 3'),
  @('Cell A','Cell B','Cell C'),
  @('Cell D','Cell E','Cell F')
) }
$blocks += @{ t='link-p'; text='Useful resource'; url='https://example.com/' }

# ============================================================================
# Below this line: rendering engine. Do not edit unless extending the template.
# ============================================================================

$scratch = Join-Path $env:TEMP "docgen_$(Get-Random)"
New-Item -ItemType Directory -Force -Path $scratch | Out-Null

$htmlPath = Join-Path $scratch "$baseName.html"
$pdfPath  = Join-Path $scratch "$baseName.pdf"
$docxPath = Join-Path $scratch "$baseName.docx"

# ----------------------------- HTML renderer --------------------------------
function Escape-Html($s) {
  return $s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;'
}
function Render-Inline-Html($text) {
  $t = Escape-Html $text
  $t = [regex]::Replace($t, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
  $t = [regex]::Replace($t, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
  $t = [regex]::Replace($t, '`([^`]+)`', '<code>$1</code>')
  return $t
}
$htmlBody = New-Object System.Text.StringBuilder
foreach ($block in $blocks) {
  switch ($block.t) {
    'title'    { [void]$htmlBody.AppendLine("<h1 class='doc-title'>$(Escape-Html $block.text)</h1>") }
    'subtitle' { [void]$htmlBody.AppendLine("<p class='doc-subtitle'>$(Escape-Html $block.text)</p>") }
    'meta'     { [void]$htmlBody.AppendLine("<p class='doc-meta'>$(Render-Inline-Html $block.text)</p>") }
    'h1'       { [void]$htmlBody.AppendLine("<h2 class='h1'>$(Escape-Html $block.text)</h2>") }
    'h2'       { [void]$htmlBody.AppendLine("<h3 class='h2'>$(Escape-Html $block.text)</h3>") }
    'h3'       { [void]$htmlBody.AppendLine("<h4 class='h3'>$(Escape-Html $block.text)</h4>") }
    'p'        { [void]$htmlBody.AppendLine("<p>$(Render-Inline-Html $block.text)</p>") }
    'b'        { [void]$htmlBody.AppendLine("<p class='bullet'>&bull; $(Render-Inline-Html $block.text)</p>") }
    'code'     { [void]$htmlBody.AppendLine("<pre class='code'>$(Escape-Html $block.text)</pre>") }
    'link-p'   {
      $url = Escape-Html $block.url
      $tx  = Escape-Html $block.text
      [void]$htmlBody.AppendLine("<p class='link-p'>&rarr; <a href='$url'>$tx</a><br><span class='url'>$url</span></p>")
    }
    'table'    {
      [void]$htmlBody.AppendLine("<table>")
      $isHeader = $true
      foreach ($row in $block.rows) {
        $tag = if ($isHeader) { 'th' } else { 'td' }
        [void]$htmlBody.AppendLine("<tr>")
        foreach ($cell in $row) { [void]$htmlBody.AppendLine("<$tag>$(Render-Inline-Html $cell)</$tag>") }
        [void]$htmlBody.AppendLine("</tr>")
        $isHeader = $false
      }
      [void]$htmlBody.AppendLine("</table>")
    }
  }
}
$html = @"
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>$baseName</title>
<style>
  @page { size: letter; margin: 0.85in; }
  html, body { font-family: 'Segoe UI', Calibri, Arial, sans-serif; color: #1f2937; line-height: 1.45; font-size: 11pt; }
  body { margin: 0; }
  h1.doc-title { font-size: 26pt; color: #3730a3; margin: 0 0 4pt 0; font-weight: 700; line-height: 1.1; }
  p.doc-subtitle { font-size: 14pt; color: #4338ca; margin: 0 0 6pt 0; font-weight: 600; }
  p.doc-meta { font-size: 9.5pt; color: #6b7280; margin: 0 0 18pt 0; border-bottom: 1px solid #e5e7eb; padding-bottom: 10pt; font-style: italic; }
  h2.h1 { font-size: 18pt; color: #3730a3; margin: 22pt 0 8pt 0; font-weight: 700; border-bottom: 2px solid #e0e7ff; padding-bottom: 4pt; }
  h3.h2 { font-size: 13.5pt; color: #1f2937; margin: 14pt 0 6pt 0; font-weight: 700; }
  h4.h3 { font-size: 11.5pt; color: #374151; margin: 10pt 0 4pt 0; font-weight: 700; }
  p { margin: 0 0 7pt 0; }
  p.bullet { margin: 0 0 5pt 18pt; text-indent: -14pt; padding-left: 14pt; }
  p.link-p { margin: 0 0 6pt 0; }
  p.link-p .url { color: #6b7280; font-size: 9pt; font-family: 'Consolas', 'Courier New', monospace; word-break: break-all; }
  pre.code { background: #f3f4f6; border: 1px solid #e5e7eb; border-radius: 4pt; padding: 9pt 11pt; font-family: 'Consolas', 'Courier New', monospace; font-size: 9.5pt; color: #111827; white-space: pre-wrap; word-break: break-word; margin: 0 0 10pt 0; line-height: 1.35; }
  code { background: #f3f4f6; padding: 0 3pt; border-radius: 3pt; font-family: 'Consolas', 'Courier New', monospace; font-size: 0.92em; color: #1e3a8a; }
  a { color: #4338ca; text-decoration: none; }
  table { border-collapse: collapse; width: 100%; margin: 0 0 12pt 0; font-size: 10pt; }
  th, td { border: 1px solid #d1d5db; padding: 5pt 8pt; text-align: left; vertical-align: top; }
  th { background: #e0e7ff; color: #1e1b4b; font-weight: 700; }
  tr:nth-child(even) td { background: #f9fafb; }
  strong { color: #0f172a; }
</style></head><body>
$($htmlBody.ToString())
</body></html>
"@
[System.IO.File]::WriteAllText($htmlPath, $html, (New-Object System.Text.UTF8Encoding $false))
Write-Output "CHECKPOINT: HTML written"

# ----------------------------- PDF via headless Chrome ----------------------
# Chrome writes "N bytes written" to STDERR on success — must NOT let that
# trigger ErrorActionPreference=Stop. Validate by file existence + size only.
$chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
if (-not (Test-Path $chrome)) { $chrome = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' }
$userDataDir = Join-Path $scratch 'browser-profile'
New-Item -ItemType Directory -Force -Path $userDataDir | Out-Null
$uri = ([System.Uri]$htmlPath).AbsoluteUri
try {
  $ErrorActionPreference = 'Continue'
  & $chrome --headless=new --disable-gpu --no-sandbox `
    "--user-data-dir=$userDataDir" `
    --no-pdf-header-footer `
    "--print-to-pdf=$pdfPath" `
    $uri | Out-Null
  $ErrorActionPreference = 'Stop'
} catch {
  $ErrorActionPreference = 'Stop'  # Chrome's stderr-on-success was caught
}
if (-not (Test-Path $pdfPath) -or (Get-Item $pdfPath).Length -lt 1000) {
  throw "PDF generation failed: $pdfPath not produced or empty"
}
Write-Output "CHECKPOINT: PDF generated"

# ----------------------------- OOXML renderer -------------------------------
function Esc-Xml($s) {
  return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' -replace '"','&quot;' -replace "'",'&apos;')
}

# Parse-Inline: split a string into runs honoring **bold**, `code`, [text](url).
# CRITICAL: do NOT use Sort-Object on array-of-pairs — when the array has one
# item the pipeline unwraps it and indexing breaks silently -> infinite loop.
function Parse-Inline($text) {
  $runs = New-Object System.Collections.ArrayList
  $pos = 0; $len = $text.Length
  while ($pos -lt $len) {
    $iBold = $text.IndexOf('**', $pos)
    $iCode = $text.IndexOf('`',  $pos)
    $iLink = $text.IndexOf('[',  $pos)
    $nextIdx = -1; $nextKind = $null
    if ($iBold -ge 0)                                              { $nextIdx = $iBold; $nextKind = 'bold' }
    if ($iCode -ge 0 -and ($nextIdx -lt 0 -or $iCode -lt $nextIdx)) { $nextIdx = $iCode; $nextKind = 'code' }
    if ($iLink -ge 0 -and ($nextIdx -lt 0 -or $iLink -lt $nextIdx)) { $nextIdx = $iLink; $nextKind = 'link' }
    if ($nextIdx -lt 0) {
      [void]$runs.Add(@{ text = $text.Substring($pos); bold=$false; code=$false; link=$null })
      break
    }
    if ($nextIdx -gt $pos) {
      [void]$runs.Add(@{ text = $text.Substring($pos, $nextIdx - $pos); bold=$false; code=$false; link=$null })
    }
    switch ($nextKind) {
      'bold' {
        $end = $text.IndexOf('**', $nextIdx + 2)
        if ($end -lt 0) {
          [void]$runs.Add(@{ text = $text.Substring($nextIdx); bold=$false; code=$false; link=$null }); $pos = $len
        } else {
          [void]$runs.Add(@{ text = $text.Substring($nextIdx + 2, $end - $nextIdx - 2); bold=$true; code=$false; link=$null }); $pos = $end + 2
        }
      }
      'code' {
        $end = $text.IndexOf('`', $nextIdx + 1)
        if ($end -lt 0) {
          [void]$runs.Add(@{ text = $text.Substring($nextIdx); bold=$false; code=$false; link=$null }); $pos = $len
        } else {
          [void]$runs.Add(@{ text = $text.Substring($nextIdx + 1, $end - $nextIdx - 1); bold=$false; code=$true; link=$null }); $pos = $end + 1
        }
      }
      'link' {
        $cb = $text.IndexOf(']', $nextIdx + 1)
        if ($cb -lt 0 -or $cb + 1 -ge $len -or $text[$cb + 1] -ne '(') {
          [void]$runs.Add(@{ text = $text.Substring($nextIdx,1); bold=$false; code=$false; link=$null }); $pos = $nextIdx + 1
        } else {
          $cp = $text.IndexOf(')', $cb + 2)
          if ($cp -lt 0) {
            [void]$runs.Add(@{ text = $text.Substring($nextIdx,1); bold=$false; code=$false; link=$null }); $pos = $nextIdx + 1
          } else {
            $linkText = $text.Substring($nextIdx + 1, $cb - $nextIdx - 1)
            $linkUrl  = $text.Substring($cb + 2, $cp - $cb - 2)
            [void]$runs.Add(@{ text = $linkText; bold=$false; code=$false; link = $linkUrl }); $pos = $cp + 1
          }
        }
      }
    }
  }
  return $runs
}

$relsList = New-Object System.Collections.ArrayList
$relIdCounter = 1
function Add-Hyperlink-Rel($url) {
  $script:relIdCounter++
  $rId = "rId$($script:relIdCounter + 100)"
  [void]$script:relsList.Add(@{ id = $rId; target = $url })
  return $rId
}

function Make-Run($run) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<w:r><w:rPr>')
  if ($run.bold) { [void]$sb.Append('<w:b/>') }
  if ($run.code) {
    [void]$sb.Append('<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="20"/><w:color w:val="1E3A8A"/><w:shd w:val="clear" w:color="auto" w:fill="F3F4F6"/>')
  }
  if ($run.link) { [void]$sb.Append('<w:color w:val="4338CA"/><w:u w:val="single"/>') }
  [void]$sb.Append('</w:rPr><w:t xml:space="preserve">' + (Esc-Xml $run.text) + '</w:t></w:r>')
  return $sb.ToString()
}
function Make-Inline-Runs($text) {
  $runs = Parse-Inline $text
  $sb = New-Object System.Text.StringBuilder
  foreach ($run in $runs) {
    if ($run.link) {
      $rId = Add-Hyperlink-Rel $run.link
      [void]$sb.Append("<w:hyperlink r:id=`"$rId`">"); [void]$sb.Append((Make-Run $run)); [void]$sb.Append('</w:hyperlink>')
    } else { [void]$sb.Append((Make-Run $run)) }
  }
  return $sb.ToString()
}

function Make-Para($text, $style) {
  $pPr = ''; $isStyled = $false
  switch ($style) {
    'title'    { $pPr = '<w:pPr><w:spacing w:before="0" w:after="100"/></w:pPr>'; $isStyled = $true }
    'subtitle' { $pPr = '<w:pPr><w:spacing w:before="0" w:after="120"/></w:pPr>'; $isStyled = $true }
    'meta'     { $pPr = '<w:pPr><w:spacing w:before="0" w:after="360"/><w:pBdr><w:bottom w:val="single" w:sz="4" w:space="6" w:color="E5E7EB"/></w:pBdr></w:pPr>'; $isStyled = $true }
    'h1'       { $pPr = '<w:pPr><w:spacing w:before="440" w:after="160"/><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="2" w:color="E0E7FF"/></w:pBdr></w:pPr>'; $isStyled = $true }
    'h2'       { $pPr = '<w:pPr><w:spacing w:before="280" w:after="120"/></w:pPr>'; $isStyled = $true }
    'h3'       { $pPr = '<w:pPr><w:spacing w:before="200" w:after="80"/></w:pPr>'; $isStyled = $true }
    'p'        { $pPr = '<w:pPr><w:spacing w:before="0" w:after="140"/></w:pPr>' }
    'bullet'   { $pPr = '<w:pPr><w:spacing w:before="0" w:after="100"/><w:ind w:left="360" w:hanging="220"/></w:pPr>' }
  }
  $inner = ''
  if ($style -eq 'bullet') {
    $inner = '<w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t xml:space="preserve">&#8226;  </w:t></w:r>'
    $inner += Make-Inline-Runs $text
  } elseif ($isStyled) {
    foreach ($run in (Parse-Inline $text)) {
      $rPr = switch ($style) {
        'title'    { '<w:rPr><w:b/><w:sz w:val="52"/><w:color w:val="3730A3"/></w:rPr>' }
        'subtitle' { '<w:rPr><w:b/><w:sz w:val="28"/><w:color w:val="4338CA"/></w:rPr>' }
        'meta'     { '<w:rPr><w:i/><w:sz w:val="19"/><w:color w:val="6B7280"/></w:rPr>' }
        'h1'       { '<w:rPr><w:b/><w:sz w:val="36"/><w:color w:val="3730A3"/></w:rPr>' }
        'h2'       { '<w:rPr><w:b/><w:sz w:val="27"/><w:color w:val="1F2937"/></w:rPr>' }
        'h3'       { '<w:rPr><w:b/><w:sz w:val="23"/><w:color w:val="374151"/></w:rPr>' }
      }
      $inner += '<w:r>' + $rPr + '<w:t xml:space="preserve">' + (Esc-Xml $run.text) + '</w:t></w:r>'
    }
  } else {
    $inner = Make-Inline-Runs $text
  }
  return "<w:p>$pPr$inner</w:p>"
}

function Make-Code-Para($text) {
  $lines = $text -split "`r?`n"
  $runs = ''
  foreach ($line in $lines) {
    $runs += '<w:r><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="19"/><w:color w:val="111827"/><w:shd w:val="clear" w:color="auto" w:fill="F3F4F6"/></w:rPr><w:t xml:space="preserve">' + (Esc-Xml $line) + '</w:t></w:r>'
    $runs += '<w:r><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="19"/></w:rPr><w:br/></w:r>'
  }
  $pPr = '<w:pPr><w:spacing w:before="120" w:after="200"/><w:ind w:left="120"/><w:shd w:val="clear" w:color="auto" w:fill="F3F4F6"/><w:pBdr><w:top w:val="single" w:sz="4" w:space="1" w:color="E5E7EB"/><w:bottom w:val="single" w:sz="4" w:space="1" w:color="E5E7EB"/><w:left w:val="single" w:sz="4" w:space="4" w:color="E5E7EB"/><w:right w:val="single" w:sz="4" w:space="4" w:color="E5E7EB"/></w:pBdr></w:pPr>'
  return "<w:p>$pPr$runs</w:p>"
}

function Make-Link-Para($text, $url) {
  $rId = Add-Hyperlink-Rel $url
  $pPr = '<w:pPr><w:spacing w:before="0" w:after="100"/></w:pPr>'
  $arrow   = '<w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:t xml:space="preserve">&#8594; </w:t></w:r>'
  $linkRun = '<w:hyperlink r:id="' + $rId + '"><w:r><w:rPr><w:color w:val="4338CA"/><w:u w:val="single"/><w:sz w:val="22"/></w:rPr><w:t xml:space="preserve">' + (Esc-Xml $text) + '</w:t></w:r></w:hyperlink>'
  $urlRun  = '<w:r><w:rPr><w:sz w:val="22"/></w:rPr><w:br/></w:r>'
  $urlRun += '<w:r><w:rPr><w:rFonts w:ascii="Consolas" w:hAnsi="Consolas"/><w:sz w:val="17"/><w:color w:val="6B7280"/></w:rPr><w:t xml:space="preserve">' + (Esc-Xml $url) + '</w:t></w:r>'
  return "<w:p>$pPr$arrow$linkRun$urlRun</w:p>"
}

function Make-Table($rows) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('<w:tbl><w:tblPr><w:tblW w:w="5000" w:type="pct"/><w:tblBorders><w:top w:val="single" w:sz="4" w:color="D1D5DB"/><w:left w:val="single" w:sz="4" w:color="D1D5DB"/><w:bottom w:val="single" w:sz="4" w:color="D1D5DB"/><w:right w:val="single" w:sz="4" w:color="D1D5DB"/><w:insideH w:val="single" w:sz="4" w:color="D1D5DB"/><w:insideV w:val="single" w:sz="4" w:color="D1D5DB"/></w:tblBorders></w:tblPr>')
  $isHeader = $true
  foreach ($row in $rows) {
    [void]$sb.Append('<w:tr>')
    foreach ($cell in $row) {
      $shading = if ($isHeader) { '<w:shd w:val="clear" w:color="auto" w:fill="E0E7FF"/>' } else { '' }
      [void]$sb.Append('<w:tc>')
      [void]$sb.Append("<w:tcPr>$shading</w:tcPr>")
      $runs = Make-Inline-Runs $cell
      [void]$sb.Append("<w:p><w:pPr><w:spacing w:before='60' w:after='60'/></w:pPr>$runs</w:p>")
      [void]$sb.Append('</w:tc>')
    }
    [void]$sb.Append('</w:tr>')
    $isHeader = $false
  }
  [void]$sb.Append('</w:tbl>')
  [void]$sb.Append('<w:p><w:pPr><w:spacing w:before="0" w:after="120"/></w:pPr></w:p>')
  return $sb.ToString()
}

Write-Output "CHECKPOINT: about to render docx body"
$body = New-Object System.Text.StringBuilder
foreach ($block in $blocks) {
  switch ($block.t) {
    'title'    { [void]$body.Append((Make-Para $block.text 'title')) }
    'subtitle' { [void]$body.Append((Make-Para $block.text 'subtitle')) }
    'meta'     { [void]$body.Append((Make-Para $block.text 'meta')) }
    'h1'       { [void]$body.Append((Make-Para $block.text 'h1')) }
    'h2'       { [void]$body.Append((Make-Para $block.text 'h2')) }
    'h3'       { [void]$body.Append((Make-Para $block.text 'h3')) }
    'p'        { [void]$body.Append((Make-Para $block.text 'p')) }
    'b'        { [void]$body.Append((Make-Para $block.text 'bullet')) }
    'code'     { [void]$body.Append((Make-Code-Para $block.text)) }
    'link-p'   { [void]$body.Append((Make-Link-Para $block.text $block.url)) }
    'table'    { [void]$body.Append((Make-Table $block.rows)) }
  }
}

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
$($body.ToString())
    <w:sectPr>
      <w:pgSz w:w="12240" w:h="15840"/>
      <w:pgMar w:top="1080" w:right="1080" w:bottom="1080" w:left="1080" w:header="720" w:footer="720" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$contentTypesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@

$rootRelsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@

$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:docDefaults>
    <w:rPrDefault>
      <w:rPr>
        <w:rFonts w:ascii="Segoe UI" w:hAnsi="Segoe UI" w:cs="Segoe UI"/>
        <w:sz w:val="22"/><w:szCs w:val="22"/><w:lang w:val="en-US"/>
      </w:rPr>
    </w:rPrDefault>
    <w:pPrDefault>
      <w:pPr><w:spacing w:after="120" w:line="280" w:lineRule="auto"/></w:pPr>
    </w:pPrDefault>
  </w:docDefaults>
</w:styles>
'@

$docRelsSb = New-Object System.Text.StringBuilder
[void]$docRelsSb.AppendLine('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
[void]$docRelsSb.AppendLine('<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">')
[void]$docRelsSb.AppendLine('  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>')
foreach ($rel in $relsList) {
  $rurl = Esc-Xml $rel.target
  [void]$docRelsSb.AppendLine("  <Relationship Id=`"$($rel.id)`" Type=`"http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink`" Target=`"$rurl`" TargetMode=`"External`"/>")
}
[void]$docRelsSb.AppendLine('</Relationships>')

Write-Output "CHECKPOINT: about to zip docx"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
function Add-Zip-Entry($zip, $entryPath, $content) {
  $entry = $zip.CreateEntry($entryPath, [System.IO.Compression.CompressionLevel]::Optimal)
  $stream = $entry.Open()
  $writer = New-Object System.IO.StreamWriter($stream, $utf8NoBom)
  $writer.Write($content); $writer.Flush(); $writer.Dispose(); $stream.Dispose()
}
if (Test-Path $docxPath) { Remove-Item $docxPath -Force }
$fs  = [System.IO.File]::Open($docxPath, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
Add-Zip-Entry $zip '[Content_Types].xml' $contentTypesXml
Add-Zip-Entry $zip '_rels/.rels' $rootRelsXml
Add-Zip-Entry $zip 'word/document.xml' $documentXml
Add-Zip-Entry $zip 'word/styles.xml' $stylesXml
Add-Zip-Entry $zip 'word/_rels/document.xml.rels' $docRelsSb.ToString()
$zip.Dispose(); $fs.Dispose()

# Copy outputs to destinations
foreach ($dest in @($docsDir, $downloadsDir)) {
  if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Force -Path $dest | Out-Null }
  Copy-Item $docxPath (Join-Path $dest "$baseName.docx") -Force
  Copy-Item $pdfPath  (Join-Path $dest "$baseName.pdf")  -Force
  $dx = (Get-Item (Join-Path $dest "$baseName.docx")).Length
  $px = (Get-Item (Join-Path $dest "$baseName.pdf")).Length
  Write-Output "$([math]::Round($dx/1KB,1)) KB  $dest\$baseName.docx"
  Write-Output "$([math]::Round($px/1KB,1)) KB  $dest\$baseName.pdf"
}

Remove-Item $scratch -Recurse -Force -ErrorAction SilentlyContinue
Write-Output "DONE."
