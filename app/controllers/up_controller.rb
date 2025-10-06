# frozen_string_literal: true

class UpController < ApplicationController
  skip_before_action :require_authentication

  def index
    head :ok
  end

  def databases
    DatabaseService.check_connections
    render json: { status: 'ok', message: 'All services are up' }, status: :ok
  end
end
