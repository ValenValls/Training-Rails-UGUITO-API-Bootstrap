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
        note_params = assure_params_presence
        context_params = { user_id: current_user.id, utility_id: current_user.utility_id }
        Note.create!(note_params.merge(context_params))
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

      def assure_params_presence
        raise Exceptions::MissingParametersError, missing_params_msg unless params[:note]
        params[:note].transform_keys! { |key| key == 'type' ? 'note_type' : key }
        note_params = params.require(:note).permit(:title, :content, :note_type)
        return note_params if note_params_present?(note_params)
        raise Exceptions::MissingParametersError, missing_params_msg
      end

      def note_params_present?(note_params)
        %i[title content note_type].all? { |param| note_params.key? param }
      end

      def missing_params_msg
        I18n.t('active_record.errors.note.missing_params')
      end

      def created_status_message
        I18n.t('active_record.messages.note.created_succesfully')
      end
    end
  end
end
