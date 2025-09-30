# 🚀 Deploy Clean N' Go to Render - Complete Guide

## Prerequisites

-   GitHub repository with your Clean N' Go code
-   Render account (free tier available)
-   Your Supabase database credentials (or use Render's PostgreSQL)

## Step 1: Prepare Your Repository

### 1.1 Push Your Code to GitHub

```bash
git add .
git commit -m "Add Render deployment configuration"
git push origin main
```

### 1.2 Verify Files Are Present

Make sure these files are in your repository root:

-   `Dockerfile.render` ✅
-   `render.yaml` ✅
-   `render-env-example.txt` ✅
-   Your Laravel application files ✅

## Step 2: Deploy to Render

### 2.1 Create New Web Service

1. Go to [Render Dashboard](https://dashboard.render.com)
2. Click **"New +"** → **"Web Service"**
3. Connect your GitHub repository
4. Select your Clean N' Go repository

### 2.2 Configure Service Settings

```
Name: clean-n-go-app
Environment: Docker
Dockerfile Path: ./Dockerfile.render
Plan: Starter (Free)
Region: Singapore (or closest to your users)
Branch: main
```

### 2.3 Set Environment Variables

Copy the variables from `render-env-example.txt` and add them in Render:

**Required Variables:**

```
APP_NAME="Clean N' Go"
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=error
CACHE_DRIVER=file
SESSION_DRIVER=file
QUEUE_CONNECTION=sync
SESSION_LIFETIME=120
```

**Database Variables (if using Supabase):**

```
DB_CONNECTION=pgsql
DB_HOST=aws-1-ap-southeast-1.pooler.supabase.com
DB_PORT=5432
DB_DATABASE=postgres
DB_USERNAME=postgres.bscddyfdbwceljvjvbro
DB_PASSWORD=pjoHCtcFje2sCItg
```

**Mail Variables (optional):**

```
MAIL_MAILER=smtp
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
SMTP_ENCRYPTION=tls
MAIL_FROM_ADDRESS=noreply@cleango.com
MAIL_FROM_NAME="Clean N' Go"
```

## Step 3: Database Setup

### Option A: Use Your Existing Supabase Database

1. Use the database credentials from your `.env` file
2. Add them as environment variables in Render
3. Make sure your Supabase database allows connections from Render's IPs

### Option B: Use Render's PostgreSQL (Recommended)

1. In Render Dashboard, click **"New +"** → **"PostgreSQL"**
2. Name it: `cleanngo-db`
3. Plan: Starter (Free)
4. Region: Same as your web service
5. Connect it to your web service

## Step 4: Deploy

### 4.1 Start Deployment

1. Click **"Create Web Service"**
2. Render will automatically:
    - Build your Docker image
    - Install dependencies
    - Run Laravel optimizations
    - Start your application

### 4.2 Monitor Deployment

-   Watch the build logs for any errors
-   Build typically takes 5-10 minutes
-   You'll get a URL like: `https://clean-n-go-app.onrender.com`

## Step 5: Post-Deployment Setup

### 5.1 Run Database Migrations

After deployment, you may need to run:

```bash
# Access your service logs in Render dashboard
# Or use Render's shell feature to run:
php artisan migrate
```

### 5.2 Verify Application

1. Visit your Render URL
2. Check that your Laravel app loads correctly
3. Test database connectivity
4. Verify file uploads work (if applicable)

## Step 6: Custom Domain (Optional)

### 6.1 Add Custom Domain

1. In Render Dashboard → Your Service → Settings
2. Add your domain (e.g., `cleango.com`)
3. Update DNS records as instructed
4. Enable SSL (automatic with Render)

## Troubleshooting

### Common Issues:

**1. Build Fails**

-   Check Dockerfile syntax
-   Verify all files are committed to GitHub
-   Check build logs for specific errors

**2. Database Connection Issues**

-   Verify database credentials
-   Check if database allows external connections
-   Ensure environment variables are set correctly

**3. Application Won't Start**

-   Check application logs in Render dashboard
-   Verify Laravel key is generated
-   Check file permissions

**4. Static Assets Not Loading**

-   Verify Vite build completed successfully
-   Check if `public/build` directory exists
-   Verify nginx configuration

### Debug Commands:

```bash
# Check Laravel configuration
php artisan config:show

# Check database connection
php artisan tinker
>>> DB::connection()->getPdo();

# Check routes
php artisan route:list

# Clear caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

## Performance Optimization

### 1. Enable Caching

Your Dockerfile already includes:

-   Config caching
-   Route caching
-   View caching

### 2. Database Optimization

-   Use connection pooling
-   Add database indexes
-   Optimize queries

### 3. Static Assets

-   Use CDN for static files
-   Enable gzip compression
-   Optimize images

## Monitoring

### 1. Render Dashboard

-   Monitor CPU and memory usage
-   Check response times
-   View error logs

### 2. Laravel Logs

-   Check `storage/logs/laravel.log`
-   Monitor application errors
-   Track performance metrics

## Security Checklist

-   ✅ Environment variables secured
-   ✅ Database credentials protected
-   ✅ APP_DEBUG=false in production
-   ✅ Secure session cookies enabled
-   ✅ HTTPS enabled (automatic with Render)
-   ✅ File uploads secured
-   ✅ SQL injection protection (Laravel ORM)

## Cost Optimization

### Free Tier Limits:

-   750 hours/month
-   Sleeps after 15 minutes of inactivity
-   Cold starts take ~30 seconds

### Upgrade Options:

-   Starter: $7/month (always on)
-   Standard: $25/month (better performance)

## Support

If you encounter issues:

1. Check Render's documentation
2. Review Laravel deployment guides
3. Check your application logs
4. Verify environment variables

---

🎉 **Congratulations!** Your Clean N' Go application should now be live on Render!
