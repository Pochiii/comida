class ApplicationController < ActionController::Base
  protect_from_forgery
  # before_filter :set_current_user :authenticate_user!
  around_filter :enable_request_on_models!

  def enable_request_on_models!
    method_for_request = instance_variable_get(:"@_request") 

    ActiveRecord::Base.send(:define_method, "request", proc { method_for_request })
    ActiveRecord::Base.class.send(:define_method, "request", proc { method_for_request })
    yield
    ActiveRecord::Base.send :remove_method, "request"
    ActiveRecord::Base.class.send :remove_method, "request"
  end

  # Put this in your models!
  # def set_current_user!
  #   self.user_id ||= Thread.current[:user].id
  # end

  #def set_current_user
  #  Thread.current[:user] = current_user
  #end

end
