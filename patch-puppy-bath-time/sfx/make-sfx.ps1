# Synthesizes the cartoon sound effects used by cues.json into sfx/*.wav (44.1 kHz mono 16-bit).
# Existing files are kept unless -Force is given, so a real recording dropped in with the same name wins.
# Run fetch-sfx.ps1 after "make-sfx.ps1 -Force" so the downloaded Mixkit sounds replace their synthesized stand-ins again.
# Usage: powershell -File make-sfx.ps1 [-Force]
param([switch]$Force)
$dir = $PSScriptRoot
Add-Type -TypeDefinition @"
using System; using System.IO; using System.Collections.Generic;
public static class Sfx {
  const int R = 44100; static Random rnd = new Random(7);
  static float[] Buf(double sec) { return new float[(int)(sec * R)]; }
  static double Noise() { return rnd.NextDouble() * 2 - 1; }
  static void Norm(float[] b) { float m = 1e-6f; foreach (var v in b) m = Math.Max(m, Math.Abs(v)); for (int i = 0; i < b.Length; i++) b[i] = b[i] / m * 0.9f; }
  public static void Save(string path, float[] b) {
    Norm(b);
    using (var w = new BinaryWriter(File.Create(path))) {
      w.Write("RIFF".ToCharArray()); w.Write(36 + b.Length * 2); w.Write("WAVE".ToCharArray());
      w.Write("fmt ".ToCharArray()); w.Write(16); w.Write((short)1); w.Write((short)1); w.Write(R); w.Write(R * 2); w.Write((short)2); w.Write((short)16);
      w.Write("data".ToCharArray()); w.Write(b.Length * 2);
      foreach (var v in b) w.Write((short)Math.Max(-32767, Math.Min(32767, v * 32767)));
    }
  }
  // sine with a frequency function, added into b at offset
  static void Tone(float[] b, int off, double dur, Func<double, double> f, Func<double, double> env, double amp) {
    double ph = 0; int n = (int)(dur * R);
    for (int i = 0; i < n && off + i < b.Length; i++) { double t = (double)i / R; ph += 2 * Math.PI * f(t) / R; b[off + i] += (float)(amp * env(t) * Math.Sin(ph)); }
  }
  // one-pole lowpass over noise with a time-varying cutoff
  static void NoiseLP(float[] b, int off, double dur, Func<double, double> cutoff, Func<double, double> env, double amp) {
    double y = 0; int n = (int)(dur * R);
    for (int i = 0; i < n && off + i < b.Length; i++) { double t = (double)i / R; double a = 1 - Math.Exp(-2 * Math.PI * cutoff(t) / R); y += a * (Noise() - y); b[off + i] += (float)(amp * env(t) * y); }
  }
  // bandpass noise (state variable filter) with a moving centre
  static void NoiseBP(float[] b, int off, double dur, Func<double, double> centre, double q, Func<double, double> env, double amp) {
    double low = 0, band = 0; int n = (int)(dur * R);
    for (int i = 0; i < n && off + i < b.Length; i++) { double t = (double)i / R; double f = 2 * Math.Sin(Math.PI * Math.Min(centre(t), R / 6.0) / R);
      double high = Noise() - low - q * band; band += f * high; low += f * band; b[off + i] += (float)(amp * env(t) * band); }
  }
  static Func<double, double> Dec(double a, double k) { return t => (t < a ? t / a : Math.Exp(-(t - a) * k)); }

  public static float[] Pop(double f0) { var b = Buf(0.14); Tone(b, 0, 0.14, t => f0 * (1 + 0.8 * Math.Exp(-t * 60)), Dec(0.002, 35), 1); return b; }
  public static float[] Bloop(double f0) { var b = Buf(0.18); Tone(b, 0, 0.18, t => f0 * (0.7 + 4 * t), Dec(0.004, 22), 1); return b; }
  public static float[] Boing() { var b = Buf(0.6); Tone(b, 0, 0.6, t => 190 + 110 * Math.Exp(-5 * t) * Math.Sin(2 * Math.PI * 13 * t) + 120 * t, Dec(0.005, 4.5), 1); Tone(b, 0, 0.6, t => 2 * (190 + 110 * Math.Exp(-5 * t) * Math.Sin(2 * Math.PI * 13 * t) + 120 * t), Dec(0.005, 6), 0.3); return b; }
  public static float[] SlideUp() { var b = Buf(0.5); Tone(b, 0, 0.5, t => 380 + 1500 * t * t * 2.4 + 15 * Math.Sin(2 * Math.PI * 9 * t), t => Math.Min(1, t / 0.03) * (t > 0.42 ? Math.Max(0, (0.5 - t) / 0.08) : 1), 1); return b; }
  public static float[] Ding() { var b = Buf(1.6); foreach (var p in new[] { new[] { 1.0, 1.0 }, new[] { 2.76, 0.45 }, new[] { 5.4, 0.2 } }) Tone(b, 0, 1.6, t => 1568 * p[0], Dec(0.002, 3 + p[0]), p[1]); return b; }
  public static float[] Twinkle() { var b = Buf(0.9); double[] notes = { 2093, 2637, 3136, 2349, 3520, 2794, 3951, 3136 };
    for (int k = 0; k < notes.Length; k++) { double f = notes[k]; Tone(b, (int)(k * 0.075 * R), 0.25, t => f, Dec(0.002, 18), 0.6 + 0.4 * rnd.NextDouble()); } return b; }
  public static float[] Whoosh(double dur, double lo, double hi) { var b = Buf(dur); NoiseBP(b, 0, dur, t => lo + (hi - lo) * Math.Sin(Math.PI * t / dur), 0.7, t => Math.Pow(Math.Sin(Math.PI * t / dur), 2), 1); return b; }
  public static float[] Splash() { var b = Buf(0.9); NoiseLP(b, 0, 0.9, t => 7000 * Math.Exp(-t * 4) + 600, Dec(0.006, 5), 1);
    for (int k = 0; k < 9; k++) { double f = 500 + 700 * rnd.NextDouble(); Tone(b, (int)((0.05 + 0.5 * rnd.NextDouble()) * R), 0.12, t => f * (0.7 + 5 * t), Dec(0.003, 30), 0.25); } return b; }
  public static float[] MudSplat() { var b = Buf(0.6); NoiseLP(b, 0, 0.6, t => 2200 * Math.Exp(-t * 6) + 250, t => (t < 0.004 ? t / 0.004 : Math.Exp(-t * 7)) * (0.75 + 0.25 * Math.Sin(2 * Math.PI * 28 * t)), 1);
    Tone(b, 0, 0.3, t => 110 * Math.Exp(-t * 4) + 45, Dec(0.003, 12), 0.8);
    for (int k = 0; k < 5; k++) { double f = 160 + 140 * rnd.NextDouble(); Tone(b, (int)((0.08 + 0.3 * rnd.NextDouble()) * R), 0.1, t => f * (0.8 + 3 * t), Dec(0.003, 35), 0.35); } return b; }
  public static float[] LensSplat() { var b = Buf(0.3); NoiseLP(b, 0, 0.3, t => 3000 * Math.Exp(-t * 14) + 400, Dec(0.002, 18), 1); Tone(b, 0, 0.15, t => 160 * Math.Exp(-t * 10) + 70, Dec(0.002, 25), 0.9); return b; }
  public static float[] Drip() { var b = Buf(0.16); Tone(b, 0, 0.16, t => 650 + 26000 * Math.Min(t, 0.03), Dec(0.002, 40), 1); return b; }
  public static float[] Squeak() { var b = Buf(0.28); double ph = 0; for (int i = 0; i < b.Length; i++) { double t = (double)i / R; ph += 2 * Math.PI * (1150 + 1600 * t + 60 * Math.Sin(2 * Math.PI * 35 * t)) / R;
      double env = Math.Min(1, t / 0.015) * Math.Max(0, Math.Min(1, (0.28 - t) / 0.05)); b[i] = (float)(env * Math.Tanh(2.5 * Math.Sin(ph))); } return b; }
  public static float[] Pat(double f0) { var b = Buf(0.12); Tone(b, 0, 0.12, t => f0 * Math.Exp(-t * 8), Dec(0.002, 40), 1); NoiseLP(b, 0, 0.04, t => 1800, Dec(0.001, 90), 0.4); return b; }
  public static float[] Xylo() { var b = Buf(0.5); double[] n = { 1047, 1319, 1047, 1319 }; for (int k = 0; k < 4; k++) { double f = n[k]; Tone(b, (int)(k * 0.07 * R), 0.3, t => f, Dec(0.001, 16), 1); Tone(b, (int)(k * 0.07 * R), 0.3, t => f * 3.9, Dec(0.001, 40), 0.2); } return b; }
  public static float[] Flutter() { var b = Buf(0.7); NoiseBP(b, 0, 0.7, t => 900, 0.5, t => Math.Sin(Math.PI * t / 0.7) * (0.55 + 0.45 * Math.Sin(2 * Math.PI * 24 * t)), 1); return b; }
  public static float[] Birds(double sec) { var b = Buf(sec); double t0 = 0.3;
    while (t0 < sec - 0.5) { int chirps = 2 + rnd.Next(3); double baseF = 2600 + 1400 * rnd.NextDouble(); double rate = 18 + 14 * rnd.NextDouble();
      for (int c = 0; c < chirps; c++) { double f = baseF * (0.9 + 0.2 * rnd.NextDouble()); double dur = 0.07 + 0.06 * rnd.NextDouble();
        Tone(b, (int)((t0 + c * (dur + 0.04)) * R), dur, t => f + 900 * Math.Sin(2 * Math.PI * rate * t) - 2500 * t, t => Math.Sin(Math.PI * t / dur), 0.5 + 0.5 * rnd.NextDouble()); }
      t0 += 0.35 + 0.55 * rnd.NextDouble(); }
    return b; }
  public static float[] Breeze(double sec) { var b = Buf(sec); NoiseLP(b, 0, sec, t => 500 + 250 * Math.Sin(2 * Math.PI * 0.23 * t), t => 0.6 + 0.4 * Math.Sin(2 * Math.PI * 0.17 * t), 1); return b; }
  public static float[] Bubbles(double sec) { var b = Buf(sec); double t0 = 0.1;
    while (t0 < sec - 0.2) { double f = 380 + 600 * rnd.NextDouble(); Tone(b, (int)(t0 * R), 0.1, t => f * (0.75 + 4 * t), Dec(0.003, 30), 0.4 + 0.6 * rnd.NextDouble()); t0 += 0.18 + 0.7 * rnd.NextDouble(); }
    return b; }
}
"@
$make = [ordered]@{
  'boing'        = { [Sfx]::Boing() }
  'mud_splat'    = { [Sfx]::MudSplat() }
  'lens_splat'   = { [Sfx]::LensSplat() }
  'whip'         = { [Sfx]::Whoosh(0.16, 900, 3500) }
  'whoosh'       = { [Sfx]::Whoosh(0.45, 300, 2800) }
  'squeak'       = { [Sfx]::Squeak() }
  'footstep'     = { [Sfx]::Pat(240) }
  'slide_up'     = { [Sfx]::SlideUp() }
  'splash'       = { [Sfx]::Splash() }
  'bloop1'       = { [Sfx]::Bloop(520) }
  'bloop2'       = { [Sfx]::Bloop(620) }
  'bloop3'       = { [Sfx]::Bloop(740) }
  'bloop4'       = { [Sfx]::Bloop(880) }
  'bloop5'       = { [Sfx]::Bloop(1050) }
  'pat'          = { [Sfx]::Pat(150) }
  'pop1'         = { [Sfx]::Pop(784) }
  'pop2'         = { [Sfx]::Pop(880) }
  'pop3'         = { [Sfx]::Pop(988) }
  'pop4'         = { [Sfx]::Pop(1175) }
  'xylo'         = { [Sfx]::Xylo() }
  'flutter'      = { [Sfx]::Flutter() }
  'drip'         = { [Sfx]::Drip() }
  'ding'         = { [Sfx]::Ding() }
  'twinkle'      = { [Sfx]::Twinkle() }
  'amb_birds'    = { [Sfx]::Birds(10) }
  'amb_bubbles'  = { [Sfx]::Bubbles(12) }
  'amb_breeze'   = { [Sfx]::Breeze(12) }
}
foreach ($name in $make.Keys) {
  $path = Join-Path $dir "$name.wav"
  if ((Test-Path $path) -and -not $Force) { "keep  $name.wav"; continue }
  [Sfx]::Save($path, (& $make[$name]))
  "made  $name.wav"
}
