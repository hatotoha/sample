require 'test_helper'

class SessionsHelperTest < ActionView::TestCase

  def setup
    @user = users(:michael)
    remember(@user) # この時点でテーブルに該当ユーザーのトークンが作成され、さらにcookiesにユーザー情報が保存される
  end

  test "current_user returns right user when session is nil" do
    assert_equal @user, current_user # まずはsession、なければcookieを使ってテーブルから対応するユーザーを探し、@current_userに代入する
    assert is_logged_in?
  end

  test "current_user returns nil when remember digest is wrong" do
    @user.update_attribute(:remember_digest, User.digest(User.new_token))
    assert_nil current_user # cookieを使ってテーブルから対応するユーザーを探すが、テーブル情報が変更されており見つからないためnilが返る
  end
end
