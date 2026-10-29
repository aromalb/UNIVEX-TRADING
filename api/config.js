// Univex Trade Docs - serves the Supabase connection settings from Vercel
// Environment Variables, so nobody has to edit any code.
// Set these in Vercel > Project > Settings > Environment Variables:
//   SUPABASE_URL              e.g. https://abcdefghijklm.supabase.co
//   SUPABASE_PUBLISHABLE_KEY  sb_publishable_...  (or SUPABASE_ANON_KEY = legacy anon key)
// The Supabase-Vercel integration names (NEXT_PUBLIC_...) are also accepted.

function isSecretKey(key) {
  if (!key) return false;
  if (key.startsWith('sb_secret_')) return true;
  // Legacy JWT keys: refuse the service_role key, which bypasses all security rules
  const parts = key.split('.');
  if (parts.length === 3) {
    try {
      const payload = JSON.parse(Buffer.from(parts[1].replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString('utf8'));
      return payload.role === 'service_role';
    } catch (e) { return false; }
  }
  return false;
}

module.exports = (req, res) => {
  const env = process.env;
  const url = (env.SUPABASE_URL || env.NEXT_PUBLIC_SUPABASE_URL || '').trim();
  let key = (env.SUPABASE_PUBLISHABLE_KEY || env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY ||
             env.SUPABASE_ANON_KEY || env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '').trim();
  let warning = '';
  if (isSecretKey(key)) { key = ''; warning = 'A secret/service_role key was supplied and has been blocked. Use the publishable or anon key.'; }
  res.setHeader('Content-Type', 'application/javascript; charset=utf-8');
  res.setHeader('Cache-Control', 'no-store');
  res.end('window.UNIVEX_CONFIG=' + JSON.stringify({ SUPABASE_URL: url, SUPABASE_KEY: key, WARNING: warning }) + ';');
};
