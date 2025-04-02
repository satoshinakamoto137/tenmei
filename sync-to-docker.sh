#!/bin/bash

set -e

echo "💖 Tenmei Mega Sync Script 💻✨"
echo "--------------------------------------"

# Load .env file
source .env

# STEP 1: Export DB
echo "🧠 Exporting local MySQL DB..."
mysqldump -u $LOCAL_DB_USER -p$LOCAL_DB_PASS $LOCAL_DB_NAME > tenmei_backup.sql

# STEP 2: Ask for Git commit message
read -p "📝 Commit message: " commit_msg

# STEP 3: Git Add + Commit + Push
echo "📦 Committing to Git..."
git add wp-content/ tenmei_backup.sql
git commit -m "$commit_msg"
git push origin $GIT_BRANCH

# STEP 4: Copy wp-content to container
echo "📂 Syncing wp-content into Docker container..."
docker cp wp-content/. tenmei-container:/var/www/html/wp-content/

# STEP 5: Fix file ownership (optional)
docker exec -it tenmei-container bash -c "chown -R www-data:www-data /var/www/html/wp-content && chmod -R 755 /var/www/html/wp-content"

# STEP 6: Copy SQL and import
echo "🛢️ Importing DB into Docker container..."
docker cp tenmei_backup.sql tenmei-db:/tenmei_backup.sql
docker exec -i tenmei-db bash -c "mysql -u $DOCKER_DB_USER -p$DOCKER_DB_PASS $DOCKER_DB_NAME < /tenmei_backup.sql"

# STEP 7: Restart
echo "🔁 Restarting containers..."
docker-compose restart

echo "🎉 DONE, BABY! Your WordPress site at http://localhost:8084 is synced & sparkling ✨"

