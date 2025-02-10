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
        process_note_params
        valid_type?(params[:note][:note_type])
        create_note
        render json: { message: created_status_message }, status: :created
      end

      def index_async
        response = execute_async(RetrieveNotesWorker, current_user.id, index_async_params)
        async_custom_response(response)
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

      def valid_type?(type)
        return if %w[review critique].include? type
        raise Exceptions::NoteTypeInvalidError
      end

      def create_note
        raise Exceptions::ContentLengthInvalidError if create_note_had_errors?
      end

      def create_note_had_errors?
        Note.create(process_note_params.merge(context_params)).errors.any?
      end

      def context_params
        { user_id: current_user.id, utility_id: current_user.utility_id }
      end

      def process_note_params
        params.require(:note)
        params[:note].transform_keys! { |key| key == 'type' ? 'note_type' : key }
        params.require(:note).require(%i[title content note_type])
        params.require(:note).permit(%i[title content note_type])
      end

      def created_status_message
        I18n.t('controller.messages.note.created_succesfully')
      end

      def index_async_params
        { author: params.require(:author) }
      end
    end
  end
end
