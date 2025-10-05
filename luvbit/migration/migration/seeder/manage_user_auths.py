from .base import BaseSeeder
from yoride.interface.db.manage.manage_user_auth import ManageUserAuth

class ManageUserAuthSeeder(BaseSeeder):
    def run(self):
        try:
            # 既存データの確認
            if self.session.query(ManageUserAuth).count() > 0:
                print("manage_user_authsテーブルには既にデータが存在します。")
                return

            # 初期データの作成
            auths = [
                ManageUserAuth(id=1, name="管理者"),
                ManageUserAuth(id=2, name="加盟店"),
                ManageUserAuth(id=3, name="バイク"),
            ]

            # データの追加
            self.session.add_all(auths)
            self.session.commit()
            print("manage_user_authsテーブルの初期データを設定しました。")

        except Exception as e:
            self.session.rollback()
            print(f"エラーが発生しました: {str(e)}")
            raise