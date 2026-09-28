# Atticus M. Kuhn

Single-page static site built from the local CV and photo gallery.

## Build

```sh
npm install
npm run build
```

Serve `index.html` and `assets/` from any static web host. The CV link opens the Google Docs version. The compiled Tailwind CSS is committed at `assets/site.css`, so the site does not need a build step on the host.

## Deploy

Run `./deploy.sh` from this directory (or any other directory). It builds the CSS, uploads `index.html` and `assets/` to the VPS, then checks that the public page and stylesheet match the local files. SSH will prompt for the VPS password unless you have an SSH key configured; the password is not stored in the script.

The VPS serves the files with nginx from `/var/www/atticusmkuhn.com`. Each deployment keeps the prior version in a timestamped sibling directory for recovery. The existing Let's Encrypt certificate and HTTP-to-HTTPS redirect remain managed by nginx.
