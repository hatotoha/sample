module SessionsHelper

  # 渡されたユーザーでログインする
  def log_in(user)
    session[:user_id] = user.id
  end

  # ユーザーのセッションを永続的にする
  def remember(user)
    # 渡されたユーザーのトークンを作成し、レコードにセットする
    user.remember
    # permanentはcookieのオプションであるexpiresに20年をセットし、signedはcookieを暗号化する
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end

  # まずはsession、なければcookieを使ってテーブルから対応するユーザーを探し、@current_userに代入する
  def current_user
    if (user_id = session[:user_id])
      @current_user ||= User.find_by(id: user_id)
    # signedで復号化される。signedはトグル形式なの？？
    elsif (user_id = cookies.signed[:user_id])
      user = User.find_by(id: user_id)
      if user && user.authenticated?(cookies[:remember_token])
        log_in user
        @current_user = user
      end
    end
  end

  # 現在ログイン中のユーザーを返す (いる場合)
  # def current_user
  #   if session[:user_id]
  #     @current_user ||= User.find_by(id: session[:user_id])
  #   end
  # end

  # ユーザーがログインしていればtrue、その他ならfalseを返す
  def logged_in?
    !current_user.nil?
  end

  # 現在のユーザーをログアウトする
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end

  # 永続的セッションを破棄する
  def forget(user)
    user.forget
    cookies.delete(:user_id)
    cookies.delete(:remember_token)
  end
end
