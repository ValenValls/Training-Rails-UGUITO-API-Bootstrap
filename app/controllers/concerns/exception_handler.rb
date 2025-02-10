# app/controllers/concerns/exception_handler.rb
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActionController::ParameterMissing, with: :render_incorrect_parameter
    rescue_from ActionController::UnpermittedParameters, with: :render_incorrect_parameter
    rescue_from ActiveRecord::RecordNotFound, with: :render_nothing_not_found
    rescue_from Exceptions::ClientForbiddenError, with: :render_client_forbidden
    rescue_from Exceptions::ClientUnauthorizedError, with: :render_client_unauthorized
    rescue_from Exceptions::InvalidCurrentClientError do |_exception|
      render_error('invalid_current_client', status: :unprocessable_entity)
    end
    rescue_from Exceptions::UtilityUnavailableError, with: :render_utility_unavailable
    rescue_from Exceptions::InvalidParameterError, with: :render_invalid_parameter
    rescue_from Exceptions::MissingParametersError, with: :render_missing_parameters
    rescue_from Exceptions::ContentLengthInvalidError, with: :render_invalid_content_length
    rescue_from Exceptions::NoteTypeInvalidError, with: :render_note_type_invalid
  end

  private

  def render_invalid_parameter(error)
    # The InvalidParameterError exception is raised with the error identifier as a parameter, and
    # the way to access this parameter is by doing error.message
    render_error(error.message)
  end

  def render_incorrect_parameter(error)
    message = I18n.t('errors.messages.internal_server_error')
    render_error(
      :param_is_missing, message: message, meta: error.message, status: :bad_request
    )
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

  def render_missing_parameters
    message = I18n.t('controller.errors.note.missing_params')
    render json: { error: message }, status: :bad_request
  end

  def render_note_type_invalid
    message = I18n.t('controller.errors.note.invalid_note_type')
    render json: { error: message }, status: :unprocessable_entity
  end

  def render_invalid_content_length
    message = I18n.t('controller.errors.note.review_too_long', limit: short_word_limit)
    render json: { error: message }, status: :unprocessable_entity
  end

  def short_word_limit
    current_user.utility.short_word_count_threshold
  end
end
