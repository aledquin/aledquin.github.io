# Publishing Instructions for aledquin.com

Your new site is already live at **https://aledquin.github.io**.

To make it available at **www.aledquin.com**, follow the steps below.

---

## Step 1: Verify GitHub Pages Settings

1. Go to https://github.com/aledquin/aledquin.github.io/settings/pages
2. Under **Source**, make sure it says **GitHub Actions**
3. Under **Custom domain**, enter `www.aledquin.com` and click Save
4. Check the box **Enforce HTTPS** once it becomes available

## Step 2: Update DNS in Squarespace

1. Log into your Squarespace account at https://account.squarespace.com
2. Go to **Domains** and click on **aledquin.com**
3. Click **DNS Settings** (or **Advanced DNS Settings**)
4. Remove any existing A records or CNAME records pointing to Google Sites
5. Add a **CNAME record**:
   - **Host**: `www`
   - **Value**: `aledquin.github.io`
6. Add **four A records** for the apex domain (`aledquin.com` without www):
   - **Host**: `@`
   - **Value**: `185.199.108.153`
   - **Host**: `@`
   - **Value**: `185.199.109.153`
   - **Host**: `@`
   - **Value**: `185.199.110.153`
   - **Host**: `@`
   - **Value**: `185.199.111.153`
7. Save all changes

DNS propagation can take up to 48 hours, but usually works within 30 minutes.

## Step 3: Verify It Works

After DNS propagates:
- Visit https://www.aledquin.com -- should show your new site
- Visit https://aledquin.com -- should redirect to www.aledquin.com
- Go back to GitHub Pages settings and confirm the green checkmark next to your custom domain

---

## Adding Photos to the Gallery

1. Download photos from Instagram (or anywhere else)
2. Place them in the `images/gallery/` folder
3. Open `gallery.html` and replace the placeholder with gallery items:

```html
<div class="gallery-grid fade-in">
  <div class="gallery-item">
    <img src="images/gallery/photo-01.jpg" alt="Description" loading="lazy">
  </div>
  <div class="gallery-item">
    <img src="images/gallery/photo-02.jpg" alt="Description" loading="lazy">
  </div>
  <!-- Add more items as needed -->
</div>
```

4. Commit and push the changes

## Adding New Recipes or Cocktails

1. Copy an existing recipe page (e.g., `recipes/guacamole.html`) as a template
2. Update the content: title, ingredients, instructions, and story
3. Add a card linking to the new page in `recipes/index.html` or `cocktails/index.html`
4. Optionally add the new item to the "Recently shared" section on the homepage (`index.html`)
5. Commit and push

## File Structure

```
aledquin.github.io/
├── index.html              (Home page)
├── about.html              (About Me)
├── coding.html             (Projects)
├── gallery.html            (Photo gallery)
├── contact.html            (Contact + social links)
├── CNAME                   (Custom domain config)
├── .nojekyll               (Disables Jekyll processing)
├── css/
│   └── style.css           (All styles)
├── js/
│   └── main.js             (Navigation, animations)
├── images/
│   └── gallery/            (Place gallery photos here)
├── cocktails/
│   ├── index.html          (Cocktails listing)
│   ├── pisco-sour.html     (Pisco Sour recipe)
│   └── capira.html         (Capira recipe)
└── recipes/
    ├── index.html          (Recipes listing)
    └── guacamole.html      (Guacamole recipe)
```
