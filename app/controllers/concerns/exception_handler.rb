# app/controllers/concerns/exception_handler.rb
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::ParameterMissing, with: :render_parameter_missing
    rescue_from ActionController::UnpermittedParameters, with: :render_incorrect_parameter
    rescue_from ActiveRecord::RecordNotFound, with: :render_nothing_not_found
    rescue_from Exceptions::ClientForbiddenError, with: :render_client_forbidden
    rescue_from Exceptions::ClientUnauthorizedError, with: :render_client_unauthorized
    rescue_from Exceptions::InvalidCurrentClientError do |_exception|
      render_error('invalid_current_client', status: :unprocessable_entity)
    end
    rescue_from Exceptions::UtilityUnavailableError, with: :render_utility_unavailable
    rescue_from Exceptions::InvalidParameterError, with: :render_invalid_parameter
    rescue_from ActiveRecord::RecordInvalid, with: :render_note_creation_error
    rescue_from ArgumentError, with: :render_incorrect_parameter
  end

  private

  def render_invalid_parameter(error)
    # The InvalidParameterError exception is raised with the error identifier as a parameter, and
    # the way to access this parameter is by doing error.message
    render_error(error.message)
  end

  def render_parameter_missing
    message = I18n.t('controller.errors.missing_parameters')
    render json: { error: message }, status: :bad_request
  end

  def render_incorrect_parameter(error)
    message = case error.message
              when /is not a valid note_type/
                status = :unprocessable_entity
                I18n.t('controller.errors.note.invalid_note_type')
              else
                status = :bad_request
                error.message
              end
    render json: { error: message }, status: status
  end

  def render_nothing_not_found
    head :not_found
  end

  def render_client_forbidden
    render_error(:client_forbidden, status: :forbidden)
  end

  def render_client_unauthorized
    render_error(:client_unauthorized, status: :unauthorized)
  end

  def render_utility_unavailable
    render_error(:utility_unavailable, status: :internal_server_error)
  end

  def render_note_creation_error(error)
    render json: { error: trim_validation_error(error.message) }, status: :unprocessable_entity
  end

  def trim_validation_error(message)
    message.gsub(I18n.t('errors.messages.model_invalid').sub(/%.*/, ''), '')
  end
end
