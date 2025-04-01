require 'rails_helper'

shared_examples 'fetching the expected notes' do
  it 'responds with expected notes' do
    expect(response_body).to eq(expected)
  end

  it 'responds with 200 status' do
    expect(response).to have_http_status(:ok)
  end
end

shared_examples 'creating with errors' do
  it 'responds with expected error status' do
    expect(response).to have_http_status(expected_status)
  end

  it 'responds with expected error message' do
    expect(response_body['error']).to eq(expected_error_message)
  end
end
describe Api::V1::NotesController, type: :controller do
  describe 'GET #index' do
    context 'when there is a user logged in' do
      include_context 'with authenticated user'
      let(:expected) do
        ActiveModel::Serializer::CollectionSerializer.new(expected_notes,
                                                          serializer: IndexNoteSerializer).as_json.map(&:stringify_keys)
      end
      let(:params) { {} }
      let(:utilities) { %i[north_utility south_utility] }
      let(:utility) { create(utilities.sample) }
      let(:user_notes) { create_list(:note, 5, user: user, utility: utility) }

      context 'when fetching all the notes for user' do
        let(:expected_notes) { user_notes }

        before do
          user_notes
          get :index, params: params
        end

        it_behaves_like 'fetching the expected notes'
      end

      context 'when fetching notes with page and page size params' do
        let(:page)            { 1 }
        let(:page_size)       { 2 }
        let(:expected_notes) { user_notes.first(2) }
        let(:params) { { page: page, page_size: page_size } }

        before do
          user_notes
          get :index, params: params
        end

        it_behaves_like 'fetching the expected notes'
      end

      context 'when fetching notes using filters' do
        let(:user_reviews) { create_list(:note, 2, :review, user: user, utility: user.utility) }
        let(:user_critiques) { create_list(:note, 2, user: user, utility: user.utility) }

        before do
          user_critiques
          user_reviews
          get :index, params: params
        end

        context 'when fetching reviews' do
          let(:expected_notes) { user_reviews }
          let(:params) { { type: 'review' } }

          it_behaves_like 'fetching the expected notes'
        end

        context 'when fetching critiques' do
          let(:expected_notes) { user_critiques }
          let(:params) { { type: 'critique' } }

          it_behaves_like 'fetching the expected notes'
        end
      end

      context 'when fetching notes with sorting' do
        let(:old_note) { create(:note, user: user, utility: user.utility, created_at: 1.day.ago) }
        let(:new_note) { create(:note, user: user, utility: user.utility) }

        before do
          old_note
          new_note
          get :index, params: params
        end

        context 'when ordering ASC' do
          let(:expected_notes) { [old_note, new_note] }
          let(:params) { { order: 'asc' } }

          it_behaves_like 'fetching the expected notes'
        end

        context 'when ordering DESC' do
          let(:expected_notes) { [new_note, old_note] }
          let(:params) { { order: 'desc' } }

          it_behaves_like 'fetching the expected notes'
        end
      end
    end

    context 'when there is not a user logged in' do
      context 'when fetching all the notes for user' do
        before { get :index }

        it_behaves_like 'unauthorized'
      end
    end
  end

  describe 'GET #show' do
    context 'when there is a user logged in' do
      include_context 'with authenticated user'

      context 'when fetching a valid note' do
        let(:note) { create(:note, user: user, utility: user.utility) }
        let(:expected) { NoteSerializer.new(note, root: false).to_json }

        before do
          note
          get :show, params: { id: note.id }
        end

        it 'responds with the note json' do
          expect(response.body).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching a invalid note' do
        before do
          get :show, params: params
        end

        context 'when fetching a note from other user' do
          let(:other_user) { create(:user) }
          let(:other_user_note) { create(:note, user: other_user) }
          let(:params) { { id: other_user_note.id } }

          it 'responds with not found' do
            expect(response).to have_http_status(:not_found)
          end
        end

        context 'when fetching a non-existing note' do
          let(:non_existing_id) { Note.maximum(:id).to_i + 1 }
          let(:params) { { id: non_existing_id } }

          it 'responds with not found' do
            expect(response).to have_http_status(:not_found)
          end
        end
      end
    end

    context 'when there is not a user logged in' do
      context 'when fetching an note' do
        before { get :show, params: { id: Faker::Number.number } }

        it_behaves_like 'unauthorized'
      end
    end
  end

  describe 'POST #create' do
    context 'when there is a user logged in' do
      include_context 'with authenticated user'

      context 'when the utility id is on the header' do
        let_it_be(:utilities) do
          %i[north_utility south_utility]
        end

        include_context 'with utility' do
          let_it_be(:utility) { create(utilities.sample) }
        end

        before do
          post :create, params: params
        end

        context 'when creating a note' do
          let(:note_type) { %w[critique review].sample }
          let(:params) { { note: { title: Faker::Lorem.word, content: Faker::Lorem.word, type: 'critique' } } }

          it 'responds with 201 status' do
            expect(response).to have_http_status(:created)
          end

          it 'responds with the correct message' do
            expect(response_body['message']).to eq(I18n.t('controller.messages.note.created_succesfully'))
          end

          it 'creates a new note in the database' do
            expect { post :create, params: params }.to change(Note, :count).by(1)
          end

          it 'the new note is from the user' do
            expect(Note.last.user).to eq(user)
          end
        end

        context 'when missing parameters' do
          let(:note_type) { %w[critique review].sample }
          let(:params_create) { { note: { type: note_type, title: Faker::Lorem.sentence, content: Faker::Lorem.sentence } } }
          let(:required_params) { %i[title content type] }
          let(:params) { params_create[:note].except(required_params.sample) }
          let(:expected_status) { :bad_request }
          let(:expected_error_message) { I18n.t('controller.errors.missing_parameters') }

          it_behaves_like 'creating with errors'
        end

        context 'when creating with invalid type' do
          let(:params) { { note: { type: Faker::Name.name, title: Faker::Lorem.sentence, content: Faker::Lorem.sentence } } }
          let(:expected_status) { :unprocessable_entity }
          let(:expected_error_message) { I18n.t('controller.errors.note.invalid_note_type') }

          it_behaves_like 'creating with errors'
        end

        context 'when creating a review too long' do
          let(:long_content) { Faker::Lorem.sentence(word_count: utility.short_word_count_threshold + 1) }
          let(:params) { { note: { type: 'review', title: Faker::Lorem.sentence, content: long_content } } }
          let(:expected_status) { :unprocessable_entity }
          let(:expected_error_message) { 'Content ' << I18n.t('active_record.errors.note.review_too_long', limit: utility.short_word_count_threshold) }

          it_behaves_like 'creating with errors'
        end
      end
    end

    context 'when there is not a user logged in' do
      context 'when creating a note' do
        before { post :create }

        it_behaves_like 'unauthorized'
      end
    end
  end
end
