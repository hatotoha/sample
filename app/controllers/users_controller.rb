class UsersController < ApplicationController
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :admin_user,     only: :destroy

  def index
    # @users = User.all
    @users = User.where(activated: true).paginate(page: params[:page])
  end

  def show
    # params[:id]は文字列型の "1" ですが、findメソッドでは自動的に整数型に変換されます
    @user = User.find(params[:id])
    unless @user.activated == true
      redirect_to root_url
      return # redirect_toでは処理は終わらないので、明示的にreturnする必要がある
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      # log_in @user
      # flash[:success] = "Welcome to the Sample App!"
      # redirect_to @user
      @user.send_activation_email
      flash[:info] = "Please check your email to activate your account."
      redirect_to root_url
    else
      render 'new'
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "Profile updated"
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    User.find(params[:id]).destroy
    flash[:success] = "User deleted"
    redirect_to users_url
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  # beforeアクション

  # ログイン済みユーザーかどうか確認
  def logged_in_user
    unless logged_in?
      store_location
      flash[:danger] = "Please log in."
      redirect_to login_url
    end
  end

  # 正しいユーザーかどうか確認
  def correct_user
    @user = User.find(params[:id])
    redirect_to(root_url) unless current_user?(@user)
  end

  # 管理者かどうか確認
  def admin_user
    redirect_to(root_url) unless current_user.admin?
  end
end
