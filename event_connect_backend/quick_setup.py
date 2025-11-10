#!/usr/bin/env python
"""
Quick setup script to reset database and run migrations
"""
import subprocess
import sys
import time

def run_command(command, description):
    """Run a shell command and print the result"""
    print(f"\n{'='*60}")
    print(f"📌 {description}")
    print(f"{'='*60}")
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        print(f"❌ Error running: {command}")
        return False
    return True

def main():
    print("\n" + "="*60)
    print("🚀 Event Connect Backend - Quick Setup")
    print("="*60)

    confirm = input("\n⚠️  This will DELETE ALL DATA in the database!\n   Continue? (yes/no): ")
    if confirm.lower() != 'yes':
        print("❌ Cancelled")
        sys.exit(0)

    # Step 1: Stop containers
    if not run_command("docker-compose down -v", "Stopping Docker containers and removing volumes"):
        sys.exit(1)

    # Step 2: Start containers
    if not run_command("docker-compose up -d", "Starting fresh MySQL container"):
        sys.exit(1)

    # Step 3: Wait for MySQL
    print("\n⏳ Waiting for MySQL to be ready...")
    max_attempts = 30
    for i in range(max_attempts):
        result = subprocess.run(
            "docker exec event_connect_mysql mysqladmin ping -h localhost --silent",
            shell=True,
            capture_output=True
        )
        if result.returncode == 0:
            print("✅ MySQL is ready!")
            break
        print(f"   Attempt {i+1}/{max_attempts}...")
        time.sleep(2)
    else:
        print("❌ MySQL failed to start")
        sys.exit(1)

    # Step 4: Run migrations
    if not run_command("python manage.py migrate", "Running migrations"):
        sys.exit(1)

    # Success
    print("\n" + "="*60)
    print("✅ Setup complete!")
    print("="*60)
    print("\n💡 Next steps:")
    print("   1. Create superuser: python manage.py createsuperuser")
    print("   2. Populate test data: python populate_data.py")
    print("   3. Run server: python manage.py runserver")
    print("\n")

if __name__ == '__main__':
    main()

