class User < ApplicationRecord
  attr_accessor :remember_me, :remember_token, :activation_token, :reset_token

  has_many :microposts, dependent: :destroy
  # userは多くのactive_relationshipを持つ
  # active_relationshipの元はrelationshipモデルで、userとはfollower_idで紐づく
  has_many :active_relationships,  class_name:  "Relationship",
                                   foreign_key: "follower_id",
                                   dependent:   :destroy
  # userは多くのpassive_relationshipsを持つ
  # passive_relationshipsの元はrelationshipモデルで、userモデルとはfollowed_idで紐づく
  has_many :passive_relationships, class_name:  "Relationship",
                                   foreign_key: "followed_id",
                                   dependent:   :destroy
  # userはactive_relationshipを介し、多くのfollowingを持つ
  # active_relationshipと紐づくので、この場合のuserとはfollower（フォローしている側）
  # つまり以下のfollowingsは、ユーザーがフォローしている人たち（followings）を示す
  # なお、followingsというのはfollowedモデルの別名
  has_many :followings, through: :active_relationships, source: :followed
  # userはpassive_relationshipsを介し、多くのfollowerを持つ
  # passive_relationshipsと紐づくので、この場合のuserとはfollowed（フォローされる側）
  # つまり以下のfollowersは、ユーザーをフォローしている人たち（followers）を示す
  has_many :followers, through: :passive_relationships, source: :follower

  before_save   :downcase_email
  before_create :create_activation_digest
  validates :name, presence: true, length: { maximum: 50 }

  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false } # 細かい違いを無視し、大文字も小文字も同じものとして扱う
  has_secure_password # has_secure_passwordメソッドは新しくレコードが追加されたときのみ、存在性のバリデーションを行う
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
    # authenticated?メソッドの引数を動的に変更することにより、実行するメソッドを動的に変更できる
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

  # パスワード再設定の属性を設定する
  def create_reset_digest
    self.reset_token = User.new_token
    update_attributes(reset_digest: User.digest(reset_token), reset_sent_at: Time.zone.now)
  end

  # パスワード再設定のメールを送信する
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end

  # パスワード再設定の期限が切れている場合はtrueを返す
  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  # ユーザーのステータスフィードを返す
  def feed
    following_ids = "SELECT followed_id FROM relationships WHERE follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids}) OR user_id = :user_id", user_id: id)
  end

  # ユーザーをフォローする
  def follow(other_user)
    self.followings << other_user
  end

  # ユーザーをフォロー解除する
  def unfollow(other_user)
    # selfは必要ないが、無いとなぜfollowed_idだけでレコードを一意に特定できるのか分からないので明示する
    self.active_relationships.find_by(followed_id: other_user.id).destroy
  end

  # 現在のユーザーがフォローしてたらtrueを返す
  def following?(other_user)
    self.followings.include?(other_user)
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
