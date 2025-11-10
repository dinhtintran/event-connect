#!/bin/bash

echo "🔄 Resetting database and migrations..."

# Stop and remove MySQL container with all data
echo "📦 Stopping Docker containers..."
docker-compose down -v

# Start MySQL container again
echo "🚀 Starting fresh MySQL container..."
docker-compose up -d

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
sleep 10

# Check if MySQL is ready
until docker exec event_connect_mysql mysqladmin ping -h localhost --silent; do
    echo "⏳ Waiting for MySQL..."
    sleep 2
done

echo "✅ MySQL is ready!"

# Run migrations
echo "🔧 Running migrations..."
python manage.py migrate

# Create superuser (optional)
echo ""
echo "💡 To create a superuser, run: python manage.py createsuperuser"
echo "💡 To populate test data, run: python populate_data.py"
echo ""
echo "✅ Database setup complete!"

