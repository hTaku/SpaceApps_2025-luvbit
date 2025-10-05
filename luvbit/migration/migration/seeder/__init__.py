from migration.manage.seeder.base import BaseSeeder
from migration.manage.seeder.manage_user_auths import ManageUserAuthSeeder

SEEDERS = [
    ManageUserAuthSeeder
]

def run_all_seeders():
    """全てのシーダーを実行する"""
    for seeder_class in SEEDERS:
        with seeder_class() as seeder:
            seeder.run()