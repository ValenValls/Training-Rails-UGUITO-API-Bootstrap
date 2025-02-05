module Api
  module V1
    class NotesController < ApplicationController
      def index
        render json: notes_paged, status: :ok, each_serializer: IndexNoteSerializer
      end

      def show
        render json: Note.find(params[:id]), status: :ok
      end

      private

      def notes_paged
        notes_ordered.page(params[:page]).per(params[:page_size])
      end

      def notes_ordered
        return notes_filtered.order(created_at: params[:order]) if params[:order].present?
        notes_filtered
      end

      def notes_filtered
        Note.where(filtering_params)
      end

      def filtering_params
        params.transform_keys! { |key| key == 'type' ? 'note_type' : key }
        params.permit(%i[note_type])
      end
    end
  end
end
