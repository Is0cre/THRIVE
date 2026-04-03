# THRIVES — PWA Setup on Proxmox

## Why PWA
- iPhone users can access without App Store
- Apple gets nothing
- Self-hosted = full control
- Works on any browser on any device
- Installable to home screen — feels native

---

## Proxmox Setup

### Recommended stack
- LXC container (lightweight, no full VM overhead)
- Nginx as web server
- Flutter web build served as static files
- HTTPS via Let's Encrypt (Certbot)

### Basic Nginx config
```nginx
server {
    listen 443 ssl;
    server_name thrives.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/thrives.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/thrives.yourdomain.com/privkey.pem;

    root /var/www/thrives;
    index index.html;

    # Security headers
    add_header Content-Security-Policy "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self';" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer" always;
    add_header Permissions-Policy "camera=(), microphone=(), geolocation=()" always;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Service worker — no cache
    location /flutter_service_worker.js {
        add_header Cache-Control "no-cache";
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## PWA Manifest Requirements
Flutter web generates manifest.json automatically.
Customise for THRIVES:
- Name: THRIVES
- Short name: THRIVES
- Theme colour: dark navy
- Background colour: dark navy
- Display: standalone
- Icons: generate at 192x192 and 512x512

---

## Service Worker
Flutter web generates service worker for offline support.
Verify it caches all assets for offline use — important for users with unreliable connections.

---

## Security Headers Checklist
- [ ] Content-Security-Policy — no external sources
- [ ] X-Frame-Options — prevent clickjacking
- [ ] X-Content-Type-Options — prevent MIME sniffing
- [ ] Referrer-Policy — no referrer leakage
- [ ] Permissions-Policy — restrict camera/mic/geo to nothing (app uses camera locally via JS, not header-restricted)

---

## Blacklight Privacy Test
Run https://themarkup.org/blacklight on deployed PWA before announcing.
Should return zero trackers, zero ad tech, zero session recording.
Document result here once tested.

---

## Deployment Steps
1. Build Flutter web: `flutter build web --release`
2. Copy build/web/* to /var/www/thrives on Proxmox LXC
3. Certbot for HTTPS: `certbot --nginx -d thrives.yourdomain.com`
4. Test on iPhone Safari — add to home screen
5. Test offline functionality
6. Run Blacklight audit
