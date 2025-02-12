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
        current_user.notes.create!(validated_create_params)
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
        transform_type!(params)
        params.permit(%i[note_type])
      end

      def validated_create_params
        params.require(:note).require(%i[title content type])
        transform_type!(params[:note])
        params[:note].permit(%i[title content note_type]).merge(context_params)
      end

      def context_params
        raise ActionController::ParameterMissing, 'Utility-ID header' if utility_code_header.nil?
        { utility_id: utility_code_header }
      end

      def utility_code_header
        @utility_code_header ||= request.headers['Utility-ID']
      end

      def transform_type!(hash)
        hash.transform_keys! { |key| key == 'type' ? 'note_type' : key }
      end

      def created_status_message
        I18n.t('controller.messages.note.created_succesfully')
      end
    end
  end
end
