# Gemstone Management System - Deployment Quick Reference

**Quick Deployment Checklist & Go-Live Guide**

---

## Quick Deployment Commands

### Backend Deployment

```bash
# 1. SSH to server
ssh user@your-server.com

# 2. Pull latest code
cd /home/ubuntu/gemstone-backend
git pull origin main

# 3. Install dependencies
npm install --production

# 4. Run migrations
npm run migrate:prod

# 5. Restart application
pm2 restart gemstone-backend

# 6. Verify status
pm2 status
pm2 logs gemstone-backend
```

### Frontend Deployment (Manus)

```bash
# 1. Build application
cd /home/ubuntu/gemstone-admin-dashboard
pnpm run build

# 2. Click "Publish" button in Management UI
# (Already configured for Manus platform)
```

### Database Backup

```bash
# Manual backup
pg_dump -U gemstone_user gemstone_production | gzip > backup_$(date +%Y%m%d_%H%M%S).sql.gz

# Restore from backup
gunzip < backup_file.sql.gz | psql -U gemstone_user gemstone_production
```

---

## 30-Minute Deployment Checklist

### Before (5 minutes)

- [ ] All code committed
- [ ] Tests passing
- [ ] Database backed up
- [ ] Team notified

### During (20 minutes)

- [ ] Deploy backend
- [ ] Run migrations
- [ ] Deploy frontend
- [ ] Verify services

### After (5 minutes)

- [ ] Test critical paths
- [ ] Check error logs
- [ ] Monitor metrics

---

## Critical Endpoints to Test

```bash
# Test API health
curl https://api.your-domain.com/health

# Test login
curl -X POST https://api.your-domain.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@gemstone.com","password":"password123"}'

# Test database
curl https://api.your-domain.com/gemstones

# Test frontend
curl https://your-domain.com/
```

---

## Rollback Procedure (If Needed)

```bash
# 1. Revert code
cd /home/ubuntu/gemstone-backend
git revert HEAD
git push origin main

# 2. Revert database (if needed)
gunzip < previous_backup.sql.gz | psql -U gemstone_user gemstone_production

# 3. Restart application
pm2 restart gemstone-backend

# 4. Verify
pm2 logs gemstone-backend
```

---

## Monitoring Dashboard Links

| Service | URL | Credentials |
|---------|-----|-------------|
| Application | https://your-domain.com | owner@gemstone.com |
| API | https://api.your-domain.com | (JWT token) |
| Database | localhost:5432 | gemstone_user |
| PM2 Monitor | localhost:9615 | (local only) |
| Nginx Status | localhost:8080/nginx_status | (local only) |

---

## Emergency Contacts

| Role | Name | Phone | Email |
|------|------|-------|-------|
| DevOps Lead | _________________ | _________________ | _________________ |
| Backend Lead | _________________ | _________________ | _________________ |
| Frontend Lead | _________________ | _________________ | _________________ |
| CTO | _________________ | _________________ | _________________ |

---

## Post-Deployment Verification

### Automated Tests

```bash
# Run smoke tests
npm run test:smoke

# Run integration tests
npm run test:integration

# Check performance
npm run test:performance
```

### Manual Tests

1. **Login Test**
   - [ ] Login with Owner account
   - [ ] Login with Accountant account
   - [ ] Login with Worker account
   - [ ] Logout successfully

2. **Inventory Test**
   - [ ] View gemstones list
   - [ ] Create new gemstone
   - [ ] Edit gemstone
   - [ ] Delete gemstone

3. **Sales Test**
   - [ ] Create new sale
   - [ ] Calculate profit correctly
   - [ ] View sales history

4. **Reports Test**
   - [ ] Generate daily report
   - [ ] Export to PDF
   - [ ] Export to Excel

5. **Notifications Test**
   - [ ] Receive notifications
   - [ ] Mark as read
   - [ ] View history

---

## Performance Baseline

Record these metrics after deployment:

| Metric | Target | Actual |
|--------|--------|--------|
| Page Load Time | < 3s | _______ |
| API Response Time | < 500ms | _______ |
| Error Rate | < 0.1% | _______ |
| Uptime | > 99.5% | _______ |
| CPU Usage | < 70% | _______ |
| Memory Usage | < 70% | _______ |
| Database Connections | < 50 | _______ |

---

## Deployment Log Template

**Date:** _____________  
**Time:** _____________  
**Deployed By:** _____________  

**Changes:**
- _________________________________
- _________________________________
- _________________________________

**Issues Encountered:**
- _________________________________
- _________________________________

**Resolution:**
- _________________________________
- _________________________________

**Verified By:** _____________  
**Time:** _____________

---

## Notes & Observations

(To be filled during deployment)

---

## Sign-Off

**Deployment Status:** [ ] SUCCESS | [ ] FAILED | [ ] ROLLED BACK

**Deployed By:** _________________ **Date:** _________

**Verified By:** _________________ **Date:** _________

---

**Keep this document for reference during deployment!**
