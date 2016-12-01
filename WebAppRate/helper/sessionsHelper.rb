module SessionsHelper

  def sign_in(user)
    session[:user_id] = user.id
    self.current_user = user
  end

  def current_user= (user)
    @current_user = user
  end

  def current_user
    @current_user ||= User.find(session[:user_id])
  end

  def signed_in?
    !current_user.nil?
  end

  def sign_out
    session[:user_id] = nil
    self.current_user = nil
  end

  def current_user?(user)
    user == current_user
  end

  def authenticate
    deny_access unless signed_in?
  end

  def deny_access
      location_saved
    redirect_to signin_path, :notice => "Please Sign In"
  end

  def redirected_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end

  private

  def location_saved
    session[:return_to] = request.fullpath
  end

  def clear_return_to
    session [:return_to] =nil
  end
end