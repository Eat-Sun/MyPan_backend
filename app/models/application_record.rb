class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class_attribute :models_logger, :redis

  self.models_logger = Logger.new(Rails.root.join('log', 'model_logger.log'))
  self.redis = Redis.new(url: "redis://localhost:6379/2")
end
