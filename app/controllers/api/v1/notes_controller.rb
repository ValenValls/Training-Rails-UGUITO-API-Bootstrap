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
    end
  end
end
