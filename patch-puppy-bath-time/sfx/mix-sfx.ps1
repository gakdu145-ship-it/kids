# Mixes the sound effects listed in cues.json under a video's original audio and renders a new MP4.
# Usage: powershell -File mix-sfx.ps1 [-Cues cues.json]
# Any sfx/<name>.wav can be replaced by a real recording (WAV, 16-bit PCM, any rate, mono or stereo).
param([string]$Cues = (Join-Path $PSScriptRoot 'cues.json'))
$ErrorActionPreference = 'Stop'
$cfg = Get-Content $Cues -Raw -Encoding UTF8 | ConvertFrom-Json
$base = (Resolve-Path (Join-Path $PSScriptRoot $cfg.base)).Path
$out = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $cfg.out))
$work = Join-Path $env:TEMP 'patch-sfx-mix'; New-Item -ItemType Directory -Force $work | Out-Null

Add-Type -AssemblyName System.Runtime.WindowsRuntime
foreach ($t in 'Windows.Storage.StorageFile,Windows.Storage', 'Windows.Storage.StorageFolder,Windows.Storage', 'Windows.Media.Editing.MediaComposition,Windows.Media.Editing',
  'Windows.Media.Editing.MediaClip,Windows.Media.Editing', 'Windows.Media.Editing.BackgroundAudioTrack,Windows.Media.Editing',
  'Windows.Media.Transcoding.MediaTranscoder,Windows.Media.Transcoding', 'Windows.Media.MediaProperties.MediaEncodingProfile,Windows.Media.MediaProperties') {
  $n, $a = $t.Split(','); $null = [Type]::GetType("$n, $a, ContentType=WindowsRuntime") }
$methods = [System.WindowsRuntimeSystemExtensions].GetMethods()
$asOp = $methods | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' }
$asAct = $methods | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncActionWithProgress`1' }
$asProg = $methods | Where-Object { $_.Name -eq 'AsTask' -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperationWithProgress`2' }
function Await($op, [Type]$t) { $task = $asOp.MakeGenericMethod($t).Invoke($null, @($op)); $task.Wait(-1) | Out-Null; $task.Result }
function File($p) { Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync($p)) ([Windows.Storage.StorageFile]) }
function NewFile($p) { $f = Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync((Split-Path $p))) ([Windows.Storage.StorageFolder]); Await ($f.CreateFileAsync((Split-Path $p -Leaf), [Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile]) }

# 1. Original audio -> 44.1 kHz stereo WAV
$baseWav = Join-Path $work 'base.wav'; $mixWav = Join-Path $work 'mix.wav'
$profile = [Windows.Media.MediaProperties.MediaEncodingProfile]::CreateWav([Windows.Media.MediaProperties.AudioEncodingQuality]::High)
$profile.Audio.SampleRate = 44100; $profile.Audio.ChannelCount = 2; $profile.Audio.BitsPerSample = 16; $profile.Audio.Bitrate = 44100 * 32
$prep = Await ((New-Object Windows.Media.Transcoding.MediaTranscoder).PrepareFileTranscodeAsync((File $base), (NewFile $baseWav), $profile)) ([Windows.Media.Transcoding.PrepareTranscodeResult])
$t = $asAct.MakeGenericMethod([double]).Invoke($null, @($prep.TranscodeAsync())); $t.Wait(-1) | Out-Null

# 2. Mix
Add-Type -TypeDefinition @"
using System; using System.IO;
public static class Mix {
  public static float[][] Read(string path, out int rate) {
    byte[] b = File.ReadAllBytes(path); int pos = 12, ch = 1, bits = 16, ds = 0, dl = 0; rate = 44100;
    while (pos + 8 <= b.Length) { string id = System.Text.Encoding.ASCII.GetString(b, pos, 4); int len = BitConverter.ToInt32(b, pos + 4);
      if (id == "fmt ") { ch = BitConverter.ToInt16(b, pos + 10); rate = BitConverter.ToInt32(b, pos + 12); bits = BitConverter.ToInt16(b, pos + 22); }
      if (id == "data") { ds = pos + 8; dl = Math.Min(len, b.Length - ds); break; } pos += 8 + len + (len & 1); }
    if (bits != 16) throw new Exception(path + ": only 16-bit PCM WAV is supported");
    int n = dl / 2 / ch; var o = new float[2][]; o[0] = new float[n]; o[1] = new float[n];
    for (int i = 0; i < n; i++) { float l = BitConverter.ToInt16(b, ds + i * ch * 2) / 32768f; float r = ch > 1 ? BitConverter.ToInt16(b, ds + i * ch * 2 + 2) / 32768f : l; o[0][i] = l; o[1][i] = r; }
    return o; }
  static float At(float[] s, int rate, int outRate, int i) { double p = (double)i * rate / outRate; int k = (int)p; if (k + 1 >= s.Length) return 0; double f = p - k; return (float)(s[k] * (1 - f) + s[k + 1] * f); }
  public static void Add(float[][] mix, int outRate, string path, double at, double gain, double pan) {
    int rate; var s = Read(path, out rate); int len = (int)((long)s[0].Length * outRate / rate); int off = (int)(at * outRate);
    double gl = gain * Math.Min(1, 1 - pan), gr = gain * Math.Min(1, 1 + pan);
    for (int i = 0; i < len && off + i < mix[0].Length; i++) { if (off + i < 0) continue; mix[0][off + i] += (float)(gl * At(s[0], rate, outRate, i)); mix[1][off + i] += (float)(gr * At(s[1], rate, outRate, i)); } }
  public static void Bed(float[][] mix, int outRate, string path, double from, double to, double gain) {
    int rate; var s = Read(path, out rate); int len = (int)((long)s[0].Length * outRate / rate); int a = (int)(from * outRate), z = Math.Min(mix[0].Length, (int)(to * outRate)); int fade = outRate / 3;
    for (int i = a; i < z; i++) { int k = (i - a) % len; double env = Math.Min(1, Math.Min((double)(i - a) / fade, (double)(z - i) / fade));
      mix[0][i] += (float)(gain * env * At(s[0], rate, outRate, k)); mix[1][i] += (float)(gain * env * At(s[1], rate, outRate, k)); } }
  // Background music that ducks under the base audio's voices. Must run before any sfx is added to mix.
  public static string Music(float[][] mix, int outRate, string path, double offset, double gain, double duck, double voiceDb, double fadeOut) {
    int rate; var s = Read(path, out rate); int n = mix[0].Length; int hop = outRate / 100;
    int frames = n / hop + 1; bool[] voice = new bool[frames];
    for (int f = 0; f < frames; f++) { double acc = 0; int c = 0; for (int i = f * hop; i < Math.Min(n, (f + 1) * hop); i++) { acc += mix[0][i] * mix[0][i] + mix[1][i] * mix[1][i]; c += 2; } voice[f] = c > 0 && 10 * Math.Log10(acc / c + 1e-12) > voiceDb; }
    // hold: treat 150 ms around detected voice as voice
    bool[] held = new bool[frames]; for (int f = 0; f < frames; f++) if (voice[f]) for (int k = Math.Max(0, f - 15); k < Math.Min(frames, f + 15); k++) held[k] = true;
    double g = held[0] ? duck : 1, att = Math.Exp(-1.0 / (0.08 * outRate)), rel = Math.Exp(-1.0 / (0.4 * outRate));
    int off = (int)(offset * rate), fo = (int)(fadeOut * outRate), fi = outRate / 50; int voiced = 0;
    for (int i = 0; i < n; i++) {
      double target = held[i / hop] ? duck : 1; if (held[i / hop]) voiced++;
      g = target < g ? target + (g - target) * att : target + (g - target) * rel;
      double env = Math.Min(1, Math.Min((double)i / fi, (double)(n - i) / fo));
      double p = off + (double)i * rate / outRate; int k = (int)p; if (k + 1 >= s[0].Length) break; double fr = p - k;
      mix[0][i] += (float)(gain * g * env * (s[0][k] * (1 - fr) + s[0][k + 1] * fr));
      mix[1][i] += (float)(gain * g * env * (s[1][k] * (1 - fr) + s[1][k + 1] * fr)); }
    return string.Format("music ducked {0:0}% of the time", 100.0 * voiced / n); }
  // Raise the whole mix to a target RMS, then a look-ahead peak limiter keeps it under the ceiling.
  public static string Master(float[][] mix, int rate, double targetRmsDb, double ceiling) {
    int n = mix[0].Length; double acc = 0; long cnt = 0;
    for (int i = 0; i < n; i++) { double v = (mix[0][i] * mix[0][i] + mix[1][i] * mix[1][i]) / 2; if (v > 1e-6) { acc += v; cnt++; } }
    double rms = 10 * Math.Log10(acc / Math.Max(1, cnt) + 1e-12); double gain = Math.Pow(10, (targetRmsDb - rms) / 20);
    int look = rate / 200; double rel = Math.Exp(-1.0 / (0.12 * rate)); float[] need = new float[n];
    for (int i = 0; i < n; i++) { double p = Math.Max(Math.Abs(mix[0][i]), Math.Abs(mix[1][i])) * gain; need[i] = (float)(p > ceiling ? ceiling / p : 1); }
    // spread each reduction back over the look-ahead window so the gain is already down when the peak arrives
    float[] env = new float[n]; float run = 1; for (int i = n - 1; i >= 0; i--) { run = Math.Min(need[i], run + (1 - run) / look); env[i] = run; }
    double g = 1; int limited = 0;
    for (int i = 0; i < n; i++) { g = env[i] < g ? env[i] : env[i] + (g - env[i]) * rel; if (g < 0.999) limited++;
      for (int c = 0; c < 2; c++) mix[c][i] = (float)Math.Max(-ceiling, Math.Min(ceiling, mix[c][i] * gain * g)); }
    return string.Format("master: rms {0:0.0} dB -> {1:0.0} dB (gain {2:+0.0;-0.0} dB), limiter active {3:0.0}% of samples", rms, targetRmsDb, 20 * Math.Log10(gain), 100.0 * limited / n); }
  public static string Write(float[][] mix, int rate, string path) {
    float peak = 0; foreach (var c in mix) foreach (var v in c) peak = Math.Max(peak, Math.Abs(v));
    int clipped = 0;
    using (var w = new BinaryWriter(File.Create(path))) { int n = mix[0].Length;
      w.Write("RIFF".ToCharArray()); w.Write(36 + n * 4); w.Write("WAVE".ToCharArray()); w.Write("fmt ".ToCharArray()); w.Write(16); w.Write((short)1); w.Write((short)2); w.Write(rate); w.Write(rate * 4); w.Write((short)4); w.Write((short)16);
      w.Write("data".ToCharArray()); w.Write(n * 4);
      for (int i = 0; i < n; i++) for (int c = 0; c < 2; c++) { double v = mix[c][i]; if (Math.Abs(v) > 0.95) { v = Math.Sign(v) * (0.95 + 0.05 * Math.Tanh((Math.Abs(v) - 0.95) / 0.05)); clipped++; } w.Write((short)(v * 32767)); } }
    return string.Format("peak {0:0.000} ({1:0.0} dBFS), limited samples {2}", peak, 20 * Math.Log10(peak + 1e-9), clipped); }
}
"@
$rate = 0; $mix = [Mix]::Read($baseWav, [ref]$rate)
if ($cfg.music) {
  $mu = $cfg.music
  [Mix]::Music($mix, $rate, (Join-Path $PSScriptRoot $mu.file), $mu.offset, $mu.gain, $mu.duck, $mu.voiceDb, $mu.fadeOut)
}
foreach ($a in $cfg.ambience) { [Mix]::Bed($mix, $rate, (Join-Path $PSScriptRoot "$($a.sfx).wav"), $a.from, $a.to, $a.gain) }
foreach ($c in $cfg.cues) { [Mix]::Add($mix, $rate, (Join-Path $PSScriptRoot "$($c.sfx).wav"), $c.t, $c.gain, $c.pan) }
if ($cfg.master) { [Mix]::Master($mix, $rate, $cfg.master.targetRmsDb, $cfg.master.ceiling) }
[Mix]::Write($mix, $rate, $mixWav)
"cues: $($cfg.cues.Count), ambience beds: $($cfg.ambience.Count)"

# 3. Video with original audio muted + mixed audio
$clip = Await ([Windows.Media.Editing.MediaClip]::CreateFromFileAsync((File $base))) ([Windows.Media.Editing.MediaClip])
$clip.Volume = 0
$comp = New-Object Windows.Media.Editing.MediaComposition
[System.Collections.Generic.ICollection[Windows.Media.Editing.MediaClip]].GetMethod('Add').Invoke($comp.Clips, @($clip)) | Out-Null
$bg = Await ([Windows.Media.Editing.BackgroundAudioTrack]::CreateFromFileAsync((File $mixWav))) ([Windows.Media.Editing.BackgroundAudioTrack])
# keep the audio exactly as long as the video so the loop has no silent tail
$extra = $bg.OriginalDuration - $clip.OriginalDuration
if ($extra -gt [TimeSpan]::Zero) { $bg.TrimTimeFromEnd = $extra }
"video $($clip.OriginalDuration.TotalSeconds)s, audio $($bg.OriginalDuration.TotalSeconds)s"
[System.Collections.Generic.ICollection[Windows.Media.Editing.BackgroundAudioTrack]].GetMethod('Add').Invoke($comp.BackgroundAudioTracks, @($bg)) | Out-Null
$vp = $clip.GetVideoEncodingProperties()
# image overlays (e.g. mud on the lens): each one pops in, slides down and fades, built from short still steps
if ($cfg.overlays) {
  foreach ($t in 'Windows.Media.Editing.MediaOverlay,Windows.Media.Editing', 'Windows.Media.Editing.MediaOverlayLayer,Windows.Media.Editing') { $n, $a = $t.Split(','); $null = [Type]::GetType("$n, $a, ContentType=WindowsRuntime") }
  $addOv = [System.Collections.Generic.ICollection[Windows.Media.Editing.MediaOverlay]].GetMethod('Add')
  $steps = 0
  foreach ($o in $cfg.overlays) {
    $layer = New-Object Windows.Media.Editing.MediaOverlayLayer
    $img = File ((Resolve-Path (Join-Path $PSScriptRoot $o.image)).Path)
    $step = 1.0 / 15; $dur = $o.to - $o.from; $count = [int][Math]::Ceiling($dur / $step)
    for ($k = 0; $k -lt $count; $k++) {
      $t0 = $k * $step; $u = $t0 / $dur
      $scale = if ($t0 -lt 0.1) { 1.15 - 1.5 * $t0 } else { 1.0 }                       # quick squash-in on impact
      $op = if ($o.from + $t0 -lt $o.fadeFrom) { 1.0 } else { [Math]::Max(0, 1 - ($o.from + $t0 - $o.fadeFrom) / ($o.to - $o.fadeFrom)) }
      $w = $vp.Width * $o.w * $scale; $x = $vp.Width * $o.x - ($w - $vp.Width * $o.w) / 2
      $y = $vp.Height * ($o.y + $o.dy * $u * $u) - ($w - $vp.Width * $o.w) / 2           # slow, accelerating slide down
      $clipImg = Await ([Windows.Media.Editing.MediaClip]::CreateFromImageFileAsync($img, [TimeSpan]::FromSeconds($step))) ([Windows.Media.Editing.MediaClip])
      $ov = New-Object Windows.Media.Editing.MediaOverlay($clipImg, (New-Object Windows.Foundation.Rect($x, $y, $w, $w)), $op)
      $ov.Delay = [TimeSpan]::FromSeconds($o.from + $t0)
      $addOv.Invoke($layer.Overlays, @($ov.psobject.BaseObject)) | Out-Null; $steps++
    }
    [System.Collections.Generic.ICollection[Windows.Media.Editing.MediaOverlayLayer]].GetMethod('Add').Invoke($comp.OverlayLayers, @($layer.psobject.BaseObject)) | Out-Null
  }
  "overlays: $($cfg.overlays.Count) images, $steps animation steps"
}
$vprof = [Windows.Media.MediaProperties.MediaEncodingProfile]::CreateMp4([Windows.Media.MediaProperties.VideoEncodingQuality]::HD1080p)
$vprof.Video.Width = $vp.Width; $vprof.Video.Height = $vp.Height; $vprof.Video.Bitrate = 8000000
$task = $asProg.MakeGenericMethod([Windows.Media.Transcoding.TranscodeFailureReason], [double]).Invoke($null, @($comp.RenderToFileAsync((NewFile $out), [Windows.Media.Editing.MediaTrimmingPreference]::Precise, $vprof)))
$task.Wait(-1) | Out-Null
"render: $($task.Result) -> $out"
