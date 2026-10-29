# Univex Trade Docs – Setup Guide (Supabase + free hosting)

This folder contains everything you need:

| File | What it is |
|---|---|
| `index.html` | The app (login screen, orders, documents, team page) |
| `api/config.js` | Reads your Supabase URL and key from Vercel Environment Variables (no editing needed) |
| `vercel.json` | Tells Vercel to serve those settings to the app |
| `supabase-setup.sql` | Creates the database tables, roles and security rules |
| `SETUP-GUIDE.md` | This guide |

Total time: about 20 minutes. Everything below uses free plans (Supabase Free + Vercel Hobby).

---

## Part A – Set up Supabase (database + login)

### 1. Create a free Supabase project
1. Go to **supabase.com** and click **Start your project**. Sign up with email or GitHub.
2. Click **New project**.
3. Fill in:
   - **Name:** `univex-trade-docs`
   - **Database password:** click *Generate a password* and **save it somewhere safe** (a password manager). This is the master database password. Staff never use it, and the app doesn't need it.
   - **Region:** choose the one closest to Dubai (for example a Middle East or Mumbai region if listed, otherwise Frankfurt).
   - **Plan:** Free.
4. Click **Create new project** and wait 1–2 minutes until the dashboard is ready.

### 2. Create the database tables and security rules
1. In the left menu, open **SQL Editor**.
2. Click **New query**.
3. Open `supabase-setup.sql` from this folder in Notepad (Windows) or TextEdit (Mac), select everything, copy it, and paste it into the query box.
4. Click **Run** (bottom right).
5. You should see **"Success. No rows returned"**.
6. Check it worked: open **Table Editor** in the left menu. You should see two tables: **profiles** and **app_docs**.

What the script sets up:
- **profiles** – one row per person, with their name and role (Admin, Staff or Viewer).
- **app_docs** – all orders, products, parties, BOE entries and company settings.
- **Security rules** – nobody can read or change anything without signing in. Viewers can only read. Only Admins can change company settings and roles.
- **Live updates** – when one person saves, everyone else sees it instantly.
- **First user becomes Admin automatically.**

### 3. Lock sign-ups so only people you add can log in
1. Open **Authentication** in the left menu.
2. Go to **Sign In / Providers**.
3. Make sure **Email** is enabled.
4. Turn **off** "**Allow new users to sign up**", then click **Save**.

Now nobody can create their own account. Only you add people.

### 4. Create your own login (the first Admin)
1. Go to **Authentication → Users**.
2. Click **Add user → Create new user**.
3. Enter your email and a strong password.
4. Tick **Auto Confirm User**.
5. Click **Create user**.

Because this is the first account, it becomes **Admin** automatically.

### 5. Copy your two connection values
1. Click **Project Settings** (gear icon, bottom left) → **API Keys**. You can also click the **Connect** button at the top of the dashboard.
2. Copy:
   - **Project URL**, which looks like `https://abcdefghijklm.supabase.co`. It's also under Project Settings → Data API.
   - **Publishable key**, which starts with `sb_publishable_`. If your project only shows legacy keys, use the **anon public** key instead (a long value starting with `eyJ`).

> **Never use the `secret` key or the `service_role` key in the app.** They bypass all security rules. The publishable/anon key is designed to be public. Your data stays protected by the login and security rules from step 2.

---

## Part B – Publish on Vercel and connect with Environment Variables

You don't edit any code. The Supabase details go into Vercel's **Environment Variables**, and the app reads them automatically.

### 6. Upload the app to Vercel
1. Go to **vercel.com/signup** and create a free **Hobby** account.
2. Go to **vercel.com/drop**.
3. Drag the **`univex-trade-docs` folder** onto the page. It must be the folder that directly contains `index.html`, `vercel.json` and the `api` folder.
4. Enter a project name, e.g. `univex-docs`, and click **Deploy**.
5. You get an address like `https://univex-docs.vercel.app`. If you open it now, you'll see **"Connect your database"**. That's expected, because the keys aren't added yet.

### 7. Add the two Supabase values as Environment Variables
1. In Vercel, open your **univex-docs** project.
2. Click **Settings** (top menu) → **Environment Variables** (left menu).
3. Add the first variable:
   - **Key:** `SUPABASE_URL`
   - **Value:** your Project URL from step 5, e.g. `https://abcdefghijklm.supabase.co`
   - **Environments:** tick **Production** and **Preview**.
   - Click **Save**.
4. Add the second variable:
   - **Key:** `SUPABASE_PUBLISHABLE_KEY`
   - **Value:** your publishable key (starts with `sb_publishable_`). If you only have the legacy key, use the **anon public** key instead (you can use the key name `SUPABASE_ANON_KEY` for it).
   - **Environments:** **Production** and **Preview**.
   - Click **Save**.

> **Never add the `secret` or `service_role` key.** The app refuses it anyway and shows a warning, because that key bypasses all security rules.

### 8. Redeploy so the variables take effect
Vercel only applies new variables to the **next** deployment.
1. Click **Deployments** (top menu).
2. On the top (latest) deployment, click the **⋯** menu → **Redeploy**.
3. Confirm **Redeploy**. If the option appears, untick **Use existing Build Cache**.
4. Wait until it says **Ready**.

**Check it worked:** open `https://univex-docs.vercel.app/config.js` in your browser. You should see one line beginning `window.UNIVEX_CONFIG={"SUPABASE_URL":"https://...` with your URL and key filled in. Then open the main address. You should see the **Sign in** screen.

### 9. Tell Supabase your web address (needed for password-reset emails)
1. In Supabase go to **Authentication → URL Configuration**.
2. **Site URL:** paste your Vercel address, e.g. `https://univex-docs.vercel.app`.
3. Under **Redirect URLs**, click **Add URL** and add the same address followed by `/**`, e.g. `https://univex-docs.vercel.app/**`.
4. Click **Save**.

### Updating the app later
- **Changing keys:** edit them in **Settings → Environment Variables**, then **Redeploy** (step 8).
- **New version of the app files:** open the project in Vercel and drag the new folder onto the project page. The variables stay as they are.
- **Your own domain (optional):** **Settings → Domains → Add**, e.g. `docs.univextrading.com`. Then use that address in step 9 too.

### 10. Sign in and set up the company
1. Open your Vercel address and sign in with the email and password from step 4.
2. Go to **Company settings** and fill in:
   - company details
   - TRN and trade licence number
   - importer code
   - bank details
   - logo and stamp

   Then click **Save settings**.
3. Optional: on the Dashboard click **Load sample data** to see a full example order, then delete it when you're done.

---

## Part C – Managing staff

### Add a staff member
1. Supabase → **Authentication → Users → Add user → Create new user**.
2. Enter their email and a temporary password, tick **Auto Confirm User**, and click **Create user**.
3. Send them the app link, their email and the temporary password.
4. In the app, open **Team & access**. They appear as **Staff**. Type their name, change the role if needed, and click **Save**.

### Roles

| Role | Can do |
|---|---|
| **Admin** | Everything: company settings, logo, stamp, restore backups, team roles |
| **Staff** | Create and edit orders, products, parties, BOE entries; download all documents |
| **Viewer** | Read and download documents only |

### Passwords
- **Staff forgot their password:** they click **Forgot password?** on the login screen, enter their email, and open the link to set a new password. The link opens the app and asks for a new password.
- **Change a password yourself:** Supabase → Authentication → Users → click the user. Use the options there to send a password recovery email.
- **Remove someone:** Supabase → Authentication → Users → select the user → **Delete user**. They lose access immediately.

> The free plan's built-in email sender only sends a small number of emails per hour. That's fine for occasional password resets. For heavy use, add your own email server under Authentication → Emails → SMTP settings.

---

## Part D – Good habits on the free plan

- **Backups:** the free plan has no automatic backups. Once a week, an admin should open **Company settings → Download backup** and keep the file safe. **Restore backup** puts it all back.
- **Pausing:** Supabase pauses free projects after **7 days with no activity**. Normal daily use keeps it awake. If it ever pauses, sign in to supabase.com and click **Restore project**. No data is lost.
- **Limits:** the free plan allows about 500 MB of database, which is tens of thousands of orders. Keep logo and stamp images small (the app shrinks them automatically).

---

## Troubleshooting

| You see | Fix |
|---|---|
| "Connect your database" | The Environment Variables are missing or misspelled (`SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`), or you didn't **Redeploy** after adding them. |
| `/config.js` shows 404 | The `api` folder or `vercel.json` wasn't uploaded. Drop the whole `univex-trade-docs` folder again onto the project. |
| "secret/service_role key … blocked" | You pasted the wrong key. Use the publishable (or anon) key, then Redeploy. |
| "Email or password is incorrect" | Check for typos, or set a new password via Forgot password. |
| "This email isn't confirmed yet" | Supabase → Authentication → Users → open the user → confirm them. Next time tick **Auto Confirm User**. |
| "Account not set up" or "Database not ready" | Run `supabase-setup.sql` again in the SQL Editor. It's safe to re-run. |
| "Your account doesn't have permission" | You're a Viewer, or a Staff member trying to change company settings. Ask an Admin. |
| Password-reset link opens a blank or wrong page | Do step 8: set the Site URL and Redirect URL to your Vercel address (e.g. `https://univex-docs.vercel.app`). |
| Vercel shows 404 | You dropped the outer folder. Drop the folder that directly contains `index.html`. |
| Updated files don't show | Make sure you dropped them onto the existing project, then hard-refresh the browser (Ctrl+Shift+R, or Cmd+Shift+R on Mac). |
| Changes don't appear on another screen | Reload the page. If the bottom-left dot never says "Live", re-run the SQL script (it switches on live updates). |
| Supabase says the project is paused | supabase.com → your project → **Restore project**. |
