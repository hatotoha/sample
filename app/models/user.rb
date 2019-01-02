class User < ApplicationRecord
  attr_accessor :remember_token
  attr_accessor :remember_me
  before_save { self.email = email.downcase }
  validates :name, presence: true, length: { maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false } # 細かい違いを無視し、大文字も小文字も同じものとして扱う
  has_secure_password # has_secure_passwordメソッドは存在性のバリデーションもするが、これは新しくレコードが追加されたときだけに適用される性質を持っている
  validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

  # 渡された文字列のハッシュ値を返す
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  # ランダムなトークンを返す。トークンとはすなわちパスワードのこと
  # パスワードはユーザーが作成するのに対し、トークンはサーバーが作成する
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # 永続セッションのためにリメンバートークンをデータベースに記憶する
  def remember
    self.remember_token = User.new_token
    # update_attributeはバリデーションを素通りする
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(remember_token)
    # 以下のremember_digestはデータベースのカラムを指している
    return false if remember_digest.nil?
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  # ユーザーのログイン情報を破棄する
  def forget
    update_attribute(:remember_digest, nil)
  end
end
