class UserController < ApplicationController
  before_filter :authenticate, :except => [:new, :show, :create]
  before_filter :correct_user, :only => [:edit, :update]
  before_filter :admin_user, :only => :destroy
  before_filter :not_signed_in, :only => [:create, :new]

  def new
    @user = User.new
    @title = "Sign up"
  end

  def show
    @user = User.new(params[:user])
    @title = @user.name
  end

  def create
    user = User.new(user_params)
    if user.save
      session[:user_id] = user.id
      redirect_to '/'

    else
      redirect_to '/signup'
    end
  end

  private

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation)
  end

end