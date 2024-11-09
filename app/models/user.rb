class User < ApplicationRecord
  include Skylight::Helpers
  authenticates_with_sorcery!

  attr_accessor :password, :password_confirmation

  validates_presence_of :password, message: "密码不能为空"

  validates_presence_of :email, message: "邮箱不能为空"
  validates_format_of :email, message: "邮箱格式不合法",
    with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i,
    if: proc { |user| !user.email.blank?}
  validates :email, uniqueness: { message: "邮箱已被注册"}

  validates_presence_of :password, message: "密码不能为空"
  validates_presence_of :password_confirmation, message: "密码确认不能为空"
  validates :password, confirmation: true
  validates :password, length: { minimum: 6, message: "密码不能小于6位" }

  before_create :defulat
  after_create :initial

  has_many :folders, dependent: :destroy
  has_many :shares, dependent: :destroy

  def self.update_used_space user_id, file_size
    begin
      user = self.select(:id, :used_space, :total_space).find user_id

      user.with_lock do
        allow_to_upload = (user.used_space + file_size) < user.total_space

        user.update_attribute!(:used_space, user.used_space + file_size) if allow_to_upload
      end

    rescue => e

      User.models_logger.error e.message
    end
  end

  instrument_method title: 'get_user'
  def self.get_user token
    user_id = Rails.cache.read token

    if user_id

      return User.find(user_id)
    else
      decoded_token = OperateToken.decode_token token

      if decoded_token
        payload = decoded_token[0]

        return User.find(payload["user_id"])
      else

        return nil
      end
    end
  end

  private
    def defulat
      self.total_space = 536870912 #512MB
      self.used_space = 0
    end

    def initial
      numbering = self.id.to_s << '_' << SecureRandom.alphanumeric(4).to_s
      self.folders.create(folder_name: 'root', numbering: numbering, ancestry: nil)
    end

end
