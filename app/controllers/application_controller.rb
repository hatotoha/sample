class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  # コントローラからヘルパーを利用する場合は、includeで読み込む必要がある
  # ちなみにviewの場合、includeせずとも全てのヘルパーが利用できる
  include SessionsHelper

  private

  # ユーザーのログインを確認する
  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "Please log in."
      redirect_to login_url
    end
  end
end
