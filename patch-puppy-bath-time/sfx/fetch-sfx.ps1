# Downloads real sound effects from Mixkit (Sound Effects Free License: commercial use OK, no attribution required)
# and converts them to sfx/<name>.wav (44.1 kHz, 16-bit, leading silence trimmed).
# The synthesized version of each replaced file is kept in sfx/synth/.
# Usage: powershell -File fetch-sfx.ps1
$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$dl = Join-Path $dir 'download'; $synth = Join-Path $dir 'synth'
New-Item -ItemType Directory -Force $dl, $synth | Out-Null

# name in cues.json -> Mixkit sound id (title)
$picks = [ordered]@{
  'squeak'     = @(1014, 'Rubber duck squeak')
  'boing'      = @(2894, 'Boing hit sound')
  'mud_splat'  = @(385,  'Falling into mud surface')
  'lens_splat' = @(2889, 'Funny cartoon fast splat')
  'splash'     = @(1311, 'Water splash')
  'splash_big' = @(2884, 'Funny cartoon splash')
  'whoosh'     = @(1490, 'Fast whoosh transition')
  'slide_up'   = @(616,  'Cartoon toy whistle')
  'amb_birds'  = @(17,   'Little birds singing in the trees')
}

Add-Type -AssemblyName System.Runtime.WindowsRuntime
foreach ($t in 'Windows.Storage.StorageFile,Windows.Storage', 'Windows.Storage.StorageFolder,Windows.Storage',
  'Windows.Media.Transcoding.MediaTranscoder,Windows.Media.Transcoding', 'Windows.Media.MediaProperties.MediaEncodingProfile,Windows.Media.MediaProperties') {
  $n, $a = $t.Split(','); $null = [Type]::GetType("$n, $a, ContentType=WindowsRuntime") }
$methods = [System.WindowsRuntimeSystemExtensions].GetMethods()
$asOp = $methods | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' }
$asAct = $methods | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncActionWithProgress`1' }
function Await($op, [Type]$t) { $task = $asOp.MakeGenericMethod($t).Invoke($null, @($op)); $task.Wait(-1) | Out-Null; $task.Result }

Add-Type -TypeDefinition @"
using System; using System.IO;
public static class Trim {
  // drops leading samples quieter than -45 dBFS (keeps 5 ms before the onset) and rewrites a plain 16-bit PCM WAV
  public static string Lead(string inPath, string outPath) {
    byte[] b = File.ReadAllBytes(inPath); int pos = 12, ch = 2, rate = 44100, ds = 0, dl = 0;
    while (pos + 8 <= b.Length) { string id = System.Text.Encoding.ASCII.GetString(b, pos, 4); int len = BitConverter.ToInt32(b, pos + 4);
      if (id == "fmt ") { ch = BitConverter.ToInt16(b, pos + 10); rate = BitConverter.ToInt32(b, pos + 12); }
      if (id == "data") { ds = pos + 8; dl = Math.Min(len, b.Length - ds); break; } pos += 8 + len + (len & 1); }
    int frame = ch * 2, n = dl / frame, start = 0; short th = (short)(32768 * 0.0056);
    for (int i = 0; i < n; i++) { bool loud = false; for (int c = 0; c < ch; c++) if (Math.Abs((int)BitConverter.ToInt16(b, ds + i * frame + c * 2)) > th) loud = true; if (loud) { start = Math.Max(0, i - rate / 200); break; } }
    int outLen = (n - start) * frame;
    // normalize to the same 0.9 peak as the synthesized effects so the gains in cues.json mean the same thing
    int peak = 1; for (int i = start * ch; i < n * ch; i++) peak = Math.Max(peak, Math.Abs((int)BitConverter.ToInt16(b, ds + i * 2)));
    double k = 0.9 * 32767 / peak;
    using (var w = new BinaryWriter(File.Create(outPath))) {
      w.Write("RIFF".ToCharArray()); w.Write(36 + outLen); w.Write("WAVE".ToCharArray()); w.Write("fmt ".ToCharArray()); w.Write(16); w.Write((short)1); w.Write((short)ch); w.Write(rate); w.Write(rate * frame); w.Write((short)frame); w.Write((short)16);
      w.Write("data".ToCharArray()); w.Write(outLen);
      for (int i = start * ch; i < n * ch; i++) w.Write((short)Math.Max(-32767, Math.Min(32767, BitConverter.ToInt16(b, ds + i * 2) * k))); }
    return string.Format("{0:0.000}s lead trimmed, {1:0.00}s long", (double)start / rate, (double)(n - start) / rate);
  }
}
"@

# Background music (Mixkit Stock Music Free License). Not kept in git: originals may not be redistributed.
$musicDir = Join-Path (Split-Path $dir) 'music'; New-Item -ItemType Directory -Force $musicDir | Out-Null
$musicMp3 = Join-Path $musicDir 'jumping-around.mp3'; $musicWav = Join-Path $musicDir 'jumping-around.wav'
if (-not (Test-Path $musicMp3)) { Invoke-WebRequest -UseBasicParsing -UserAgent 'Mozilla/5.0' -Uri 'https://assets.mixkit.co/music/8/8.mp3' -OutFile $musicMp3 }
if (-not (Test-Path $musicWav)) {
  $src = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($musicMp3)) ([Windows.Storage.StorageFile])
  $folder = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($musicDir)) ([Windows.Storage.StorageFolder])
  $dst = Await ($folder.CreateFileAsync('jumping-around.wav', [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
  $p = [Windows.Media.MediaProperties.MediaEncodingProfile]::CreateWav([Windows.Media.MediaProperties.AudioEncodingQuality]::High)
  $p.Audio.SampleRate = 44100; $p.Audio.ChannelCount = 2; $p.Audio.BitsPerSample = 16; $p.Audio.Bitrate = 44100 * 32
  $prep = Await ((New-Object Windows.Media.Transcoding.MediaTranscoder).PrepareFileTranscodeAsync($src, $dst, $p)) ([Windows.Media.Transcoding.PrepareTranscodeResult])
  $t = $asAct.MakeGenericMethod([double]).Invoke($null, @($prep.TranscodeAsync())); $t.Wait(-1) | Out-Null
}
"music       mixkit #8     Jumping Around -> music\jumping-around.wav"

foreach ($name in $picks.Keys) {
  $id, $title = $picks[$name]
  $mp3 = Join-Path $dl "mixkit-$id.mp3"
  $fresh = -not (Test-Path $mp3)
  if ($fresh) { Invoke-WebRequest -UseBasicParsing -UserAgent 'Mozilla/5.0' -Uri "https://assets.mixkit.co/active_storage/sfx/$id/$id-preview.mp3" -OutFile $mp3 }
  $target = Join-Path $dir "$name.wav"
  # back up the synthesized stand-in only on first download; on reruns $target is already the Mixkit file
  if ($fresh -and (Test-Path $target) -and -not (Test-Path (Join-Path $synth "$name.wav"))) { Copy-Item $target (Join-Path $synth "$name.wav") }
  $raw = Join-Path $dl "$name.raw.wav"
  $src = Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($mp3)) ([Windows.Storage.StorageFile])
  $folder = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync($dl)) ([Windows.Storage.StorageFolder])
  $dst = Await ($folder.CreateFileAsync((Split-Path $raw -Leaf), [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
  $p = [Windows.Media.MediaProperties.MediaEncodingProfile]::CreateWav([Windows.Media.MediaProperties.AudioEncodingQuality]::High)
  $p.Audio.SampleRate = 44100; $p.Audio.ChannelCount = 2; $p.Audio.BitsPerSample = 16; $p.Audio.Bitrate = 44100 * 32
  $prep = Await ((New-Object Windows.Media.Transcoding.MediaTranscoder).PrepareFileTranscodeAsync($src, $dst, $p)) ([Windows.Media.Transcoding.PrepareTranscodeResult])
  if (-not $prep.CanTranscode) { throw "$name : cannot convert ($($prep.FailureReason))" }
  $t = $asAct.MakeGenericMethod([double]).Invoke($null, @($prep.TranscodeAsync())); $t.Wait(-1) | Out-Null
  "{0,-11} mixkit #{1,-5} {2,-34} {3}" -f $name, $id, $title, [Trim]::Lead($raw, $target)
  Remove-Item $raw
}
