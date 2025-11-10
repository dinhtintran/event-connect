#!/bin/bash

echo "🔍 Checking for MySQL processes..."

# Check if MySQL is running locally on port 3306
if lsof -Pi :3306 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo "⚠️  Port 3306 is in use!"
    echo ""
    echo "Processes using port 3306:"
    lsof -i :3306
    echo ""
    echo "This might be:"
    echo "1. Local MySQL installed via Homebrew"
    echo "2. Another Docker container"
    echo ""
    echo "To stop local MySQL (Homebrew):"
    echo "  brew services stop mysql"
    echo ""
    echo "To stop all Docker MySQL containers:"
    echo "  docker stop \$(docker ps -q --filter ancestor=mysql:8.0)"
    echo ""
    read -p "Do you want to stop local MySQL service? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Stopping local MySQL..."
        brew services stop mysql 2>/dev/null || echo "MySQL service not found or already stopped"
        sleep 2
    fi
fi

echo ""
echo "🐳 Starting Docker MySQL container..."
docker-compose down -v
docker-compose up -d

echo ""
echo "⏳ Waiting for MySQL to be ready..."
sleep 5

max_attempts=30
for i in $(seq 1 $max_attempts); do
    if docker exec event_connect_mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo "✅ MySQL is ready!"
        break
    fi
    echo "   Attempt $i/$max_attempts..."
    sleep 2
done

echo ""
echo "🔧 Running migrations..."
python manage.py migrate

echo ""
echo "✅ Setup complete!"
echo ""
echo "💡 Next steps:"
echo "  1. Create superuser: python manage.py createsuperuser"
echo "  2. Run server: python manage.py runserver"
echo ""

