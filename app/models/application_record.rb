class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  class_attribute :models_logger

  self.models_logger = Logger.new(Rails.root.join('log', 'model_error.log'))
end
