# frozen_string_literal: true

# This concern can be included in controllers to automatically track
# performance metrics for controller actions using ElasticAPM
module PerformanceTracking
  extend ActiveSupport::Concern

  included do
    around_action :track_controller_action, if: -> { AppPerformance.apm_available? }
    rescue_from StandardError, with: :track_error if AppPerformance.apm_available?
  end

  private

  def track_controller_action
    # Add user info if available, but we haven't implemented any authentication yet
    # if respond_to?(:current_user) && current_user
    #   AppPerformance.set_user(
    #     id: current_user.id,
    #     email: current_user.email,
    #     username: current_user.try(:username)
    #   )
    # end

    # Add request context
    # path and method already tracked automatically by ElasticAPM
    AppPerformance.set_custom_context(
      request: {
        query_parameters:  request.query_parameters.to_h,
        remote_ip: request.remote_ip
      }
    )
    yield
  end

  def track_error(exception)
    AppPerformance.report_error(exception, handled: true)
    raise exception # Re-raise the exception after tracking it
  end
end
