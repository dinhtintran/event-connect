"""
Script để reset database và tạo lại từ đầu
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'event_connect_backend.settings')
django.setup()

from django.db import connection

def reset_database():
    print("🔥 Đang reset database...")
    
    with connection.cursor() as cursor:
        # Disable foreign key checks (SQLite syntax)
        cursor.execute('PRAGMA foreign_keys = OFF;')
        
        # Get all tables (SQLite syntax)
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
        tables = cursor.fetchall()
        
        print(f"\n📋 Tìm thấy {len(tables)} bảng")
        
        # Drop all tables
        for table in tables:
            table_name = table[0]
            print(f"  ❌ Xóa bảng: {table_name}")
            cursor.execute(f'DROP TABLE IF EXISTS "{table_name}";')
        
        # Enable foreign key checks (SQLite syntax)
        cursor.execute('PRAGMA foreign_keys = ON;')
        
        print("\n✅ Database đã được làm sạch!")
        print("\n📝 Tiếp theo:")
        print("  1. python manage.py migrate")
        print("  2. python populate_data.py")

if __name__ == '__main__':
    confirm = input("\n⚠️  CẢNH BÁO: Script này sẽ XÓA TẤT CẢ dữ liệu trong database!\n   Bạn có chắc chắn muốn tiếp tục? (yes/no): ")
    if confirm.lower() == 'yes':
        reset_database()
    else:
        print("❌ Đã hủy")
