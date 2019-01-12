class User < ApplicationRecord
  attr_accessor :remember_me, :remember_token, :activation_token
  before_save   :downcase_email
  before_create :create_activation_digest
  validates :name, presence: true, length: { maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false } # 細かい違いを無視し、大文字も小文字も同じものとして扱う
  has_secure_password # has_secure_passwordメソッドは存在性のバリデーションもするが、これは新しくレコードが追加されたときだけに適用される性質を持っている
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # 渡された文字列のハッシュ値を返す
  def self.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返す。トークンとはすなわちパスワードのこと
  # パスワードはユーザーが作成するのに対し、トークンはサーバーが作成する
  def self.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続セッションのためにリメンバートークンをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    # update_attributeはバリデーションを素通りする
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(attribute, token)
    # sendメソッドは、引数として与えられたメソッドを実行するためのメソッド
    # 引数を動的に変更することにより、実行するメソッドを動的に変更できる
    digest = self.send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end

  # アカウントを有効にする
  def activate
    update_attributes(activated: true, activated_at: Time.zone.now )
  end

  # 有効化用のメールを送信する
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  private

  # メールアドレスをすべて小文字にする
  def downcase_email
    self.email.downcase!
  end

  # 有効化トークンとダイジェストを作成および代入する
  def create_activation_digest
    self.activation_token  = User.new_token
    self.activation_digest = User.digest(activation_token)
  end
end
