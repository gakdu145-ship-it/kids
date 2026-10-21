# Draws cartoon mud splats (transparent PNG) used as the "mud on the lens" overlay in scene1.
# Usage: powershell -File make-splats.ps1
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System; using System.Drawing; using System.Drawing.Drawing2D; using System.Drawing.Imaging;
public static class Splat {
  public static void Make(string path, int seed, int size) {
    var rnd = new Random(seed); int S = size; float c = S / 2f, R = S * 0.27f;
    using (var big = new Bitmap(S, S, PixelFormat.Format32bppArgb)) {
      using (var g = Graphics.FromImage(big)) {
        g.SmoothingMode = SmoothingMode.AntiAlias; g.Clear(Color.Transparent);
        var mud = Color.FromArgb(238, 110, 72, 38); var dark = Color.FromArgb(240, 76, 47, 22);
        using (var br = new SolidBrush(mud)) {
          // lumpy body: a few overlapping blobs instead of one circle
          for (int i = 0; i < 6; i++) { double a = rnd.NextDouble() * Math.PI * 2; float off = R * 0.35f * (float)rnd.NextDouble();
            float rx = R * (0.55f + 0.35f * (float)rnd.NextDouble()), ry = rx * (0.75f + 0.4f * (float)rnd.NextDouble());
            g.FillEllipse(br, c + off * (float)Math.Cos(a) - rx, c + off * (float)Math.Sin(a) - ry, 2 * rx, 2 * ry); }
          // short thick splash arms that taper to a round tip, spaced unevenly
          int arms = 5 + rnd.Next(3); double a0 = rnd.NextDouble() * Math.PI * 2;
          for (int i = 0; i < arms; i++) { double a = a0 + Math.PI * 2 * (i + (rnd.NextDouble() - 0.5) * 0.7) / arms;
            float len = R * (0.35f + 0.55f * (float)rnd.NextDouble()); float wb = R * (0.28f + 0.2f * (float)rnd.NextDouble()); float wt = wb * 0.35f;
            float cx = (float)Math.Cos(a), cy = (float)Math.Sin(a), nx = -cy, ny = cx; float r0 = R * 0.75f, r1 = R * 0.75f + len;
            var poly = new PointF[] { new PointF(c + cx * r0 + nx * wb / 2, c + cy * r0 + ny * wb / 2), new PointF(c + cx * r1 + nx * wt / 2, c + cy * r1 + ny * wt / 2),
                                      new PointF(c + cx * r1 - nx * wt / 2, c + cy * r1 - ny * wt / 2), new PointF(c + cx * r0 - nx * wb / 2, c + cy * r0 - ny * wb / 2) };
            g.FillPolygon(br, poly); float d = wt * 1.3f; g.FillEllipse(br, c + cx * r1 - d / 2, c + cy * r1 - d / 2, d, d); }
          // mud on glass runs down: 2-3 drips from the lower edge with a bulb at the end
          int drips = 2 + rnd.Next(2);
          for (int i = 0; i < drips; i++) { float x = c + R * (-0.55f + 1.1f * (float)rnd.NextDouble()); float w = R * (0.16f + 0.12f * (float)rnd.NextDouble()); float len = R * (0.55f + 0.7f * (float)rnd.NextDouble());
            float y0 = c + R * 0.45f; g.FillRectangle(br, x - w / 2, y0, w, len); float d = w * 1.5f; g.FillEllipse(br, x - d / 2, y0 + len - d / 2, d, d); }
          // a few loose drops near the body
          for (int i = 0; i < 7; i++) { double a = rnd.NextDouble() * Math.PI * 2; float dist = R * (1.35f + 0.5f * (float)rnd.NextDouble()); float d = R * (0.08f + 0.12f * (float)rnd.NextDouble());
            g.FillEllipse(br, c + dist * (float)Math.Cos(a) - d / 2, c + dist * (float)Math.Sin(a) - d / 2, d, d); }
        }
        // darker, thicker centre
        using (var gp = new GraphicsPath()) { gp.AddEllipse(c - R * 0.75f, c - R * 0.7f, R * 1.5f, R * 1.4f);
          using (var pb = new PathGradientBrush(gp) { CenterColor = dark, SurroundColors = new[] { Color.FromArgb(0, 76, 47, 22) } }) g.FillPath(pb, gp); }
        // wet highlights
        using (var hb = new SolidBrush(Color.FromArgb(110, 255, 244, 222))) { g.FillEllipse(hb, c - R * 0.5f, c - R * 0.55f, R * 0.42f, R * 0.2f); g.FillEllipse(hb, c - R * 0.02f, c - R * 0.66f, R * 0.11f, R * 0.07f); }
      }
      // soften: it is on the lens, so slightly out of focus
      using (var small = new Bitmap(S / 3, S / 3, PixelFormat.Format32bppArgb)) {
        using (var g = Graphics.FromImage(small)) { g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.DrawImage(big, 0, 0, S / 3, S / 3); }
        using (var outp = new Bitmap(S, S, PixelFormat.Format32bppArgb)) {
          using (var g = Graphics.FromImage(outp)) { g.InterpolationMode = InterpolationMode.HighQualityBicubic; g.Clear(Color.Transparent); g.DrawImage(small, 0, 0, S, S); }
          outp.Save(path, ImageFormat.Png); } }
    }
  }
}
"@
foreach ($s in @(@('splat1', 11), @('splat2', 23), @('splat3', 37))) { [Splat]::Make((Join-Path $PSScriptRoot "$($s[0]).png"), $s[1], 600); "made $($s[0]).png" }
