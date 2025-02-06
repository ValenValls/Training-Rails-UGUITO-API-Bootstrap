module Api
  module V1
    class NotesController < ApplicationController
      before_action :authenticate_user!
      def index
        render json: paged_notes, status: :ok, each_serializer: IndexNoteSerializer
      end

      def show
        render json: current_user.notes.find(params[:id]), status: :ok
      end

      def create
        note_params = process_note_params
        valid_type?(note_params)
        context_params = { user_id: current_user.id, utility_id: current_user.utility_id }
        note = Note.create(note_params.merge(context_params))
        raise Exceptions::ContentLengthInvalidError, too_long_message if note.errors.any?
        render json: { message: created_status_message }, status: :created
      end

      private

      def paged_notes
        ordered_notes.page(params[:page]).per(params[:page_size])
      end

      def ordered_notes
        return filtered_notes.order(created_at: params[:order]) if params[:order].present?
        filtered_notes
      end

      def filtered_notes
        current_user.notes.where(filtering_params)
      end

      def filtering_params
        params.transform_keys! { |key| key == 'type' ? 'note_type' : key }
        params.permit(%i[note_type])
      end

      def process_note_params
        raise Exceptions::MissingParametersError unless params[:note]
        params[:note].transform_keys! { |key| key == 'type' ? 'note_type' : key }
        note_params = params.require(:note).permit(:title, :content, :note_type)
        return note_params if note_params_present?(note_params)
        raise Exceptions::MissingParametersError
      end

      def note_params_present?(note_params)
        %i[title content note_type].all? { |param| note_params.key? param }
      end

      def valid_type?(note_params)
        return if %w[review critique].include? note_params[:note_type]
        raise Exceptions::NoteTypeInvalidError
      end

      def created_status_message
        I18n.t('response.messages.note.created_succesfully')
      end

      def too_long_message
        I18n.t(
          'response.errors.note.review_too_long',
          limit: current_user.utility.short_threshold
        )
      end
    end
  end
end
