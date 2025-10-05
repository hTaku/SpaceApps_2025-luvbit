from alembic import context
from migration.manage.seeder import run_all_seeders

# ...existing code...

def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    # ...existing code...

    try:
        with context.begin_transaction():
            context.run_migrations()
        
        # マイグレーション成功後にシーダーを実行
        run_all_seeders()
        
    except Exception as e:
        print(f"Error during migration: {str(e)}")
        raise

# ...existing code...