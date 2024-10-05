class User < ApplicationRecord
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
    user = self.lock("FOR UPDATE NOWAIT").find user_id
    allow_to_upload = ( user.used_space + file_size) < user.total_space

    user.update_attribute!(:used_space, user.used_space + file_size) if allow_to_upload
  end

  private
    # def password_required?
    #   p "new_record?", new_record?
    #   p "password.present?", password.present?
    #   p "password_confirmation.present?", password_confirmation.present?
    #   new_record? || password.present? || password_confirmation.present?
    # end

    # def password_confirmation_required?
    #   new_record? || password_confirmation.present?
    # end

    def defulat
      self.total_space = 536870912 #512MB
      self.used_space = 0
    end

    def initial
      self.folders.create(folder_name: 'root', ancestry: nil)
    end

end
