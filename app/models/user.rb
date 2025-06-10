class User < ApplicationRecord
  # include Skylight::Helpers
  authenticates_with_sorcery!

  attr_accessor :password, :password_confirmation

  validates_presence_of :password, message: '密码不能为空'

  validates_presence_of :phone, message: '手机号不能为空'
  validates_format_of :phone, message: '手机号格式不合法',
                              with: /\A1[3-9]\d{9}\z/,
                              if: proc { |user| !user.phone.blank? }

  validates_presence_of :email, message: '邮箱不能为空'
  validates_format_of :email, message: '邮箱格式不合法',
                              with: /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i,
                              if: proc { |user| !user.email.blank? }
  validates :email, uniqueness: { message: '邮箱已被注册' }

  validates_presence_of :password, message: '密码不能为空'
  validates_presence_of :password_confirmation, message: '密码确认不能为空'
  validates :password, confirmation: true
  validates :password, length: { minimum: 6, message: '密码不能小于6位' }

  before_create :defulat
  after_create :initial

  has_many :folders, dependent: :destroy
  has_many :shares, dependent: :destroy
  has_many :recycle_bin, dependent: :destroy

  def self.get_free_space(user_id)
    User.where(id: user_id).pluck(Arel.sql('total_space - used_space')).first
  end

  def self.update_used_space(user_id, file_size)
    user = lock(true).select(:id, :used_space, :total_space).find user_id

    allow_to_upload = (user.used_space + file_size) < user.total_space
    user.update_attribute!(:used_space, user.used_space + file_size) if allow_to_upload
  rescue StandardError => e
    User.models_logger.error e.message
  end

  def self.get_user(token, req: 'id')
    user_id = Rails.cache.read token

    if user_id
      return user_id if req == 'id'

      find user_id

    else
      decoded_token = OperateToken.decode_token token

      return nil unless decoded_token

      payload = decoded_token[0]

      return payload['user_id'] if req == 'id'

      find payload['user_id']

    end
  end

  def self.get_root(user_id)
    Folder.find_by(user_id: user_id, folder_name: 'root')
  end

  private

  def defulat
    self.total_space = 536_870_912 # 512MB
    self.used_space = 0
  end

  def initial
    numbering = id.to_s << '_' << SecureRandom.alphanumeric(4).to_s
    folders.create(folder_name: 'root', numbering: numbering, ancestry: nil, in_bins: false)
  end
end
