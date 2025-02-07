require 'rails_helper'

shared_examples 'fetch filtered' do
  let(:other_type) { note_type == 'review' ? 'critique' : 'review' }
  let(:notes_expected) { create_list(:note, 2, note_type: note_type, user: user, utility: user.utility) }
  let(:expected) do
    ActiveModel::Serializer::CollectionSerializer.new(notes_expected,
                                                      serializer: IndexNoteSerializer).to_json
  end

  before do
    create_list(:note, 2, note_type: other_type, user: user, utility: user.utility)
    expected
    get :index, params: { type: note_type }
  end

  it 'responds with expected notes' do
    expect(response_body.to_json).to eq(expected)
  end

  it 'responds with 200 status' do
    expect(response).to have_http_status(:ok)
  end
end

shared_examples 'creating missing parameters' do
  before do
    post :create, params: params_create
  end

  it 'responds with 400 status' do
    expect(response).to have_http_status(:bad_request)
  end
end

describe Api::V1::NotesController, type: :controller do
  describe 'GET #index' do
    let(:user_notes) { create_list(:note, 5, user: user, utility: user.utility) }

    context 'when there is a user logged in' do
      include_context 'with authenticated user'

      context 'when fetching all the notes for user' do
        let(:notes_expected) { user_notes }
        let(:expected) do
          ActiveModel::Serializer::CollectionSerializer.new(notes_expected,
                                                            serializer: IndexNoteSerializer).to_json
        end

        before do
          expected
          get :index
        end

        it 'responds with the expected notes json' do
          expect(response_body.to_json).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching notes with page and page size params' do
        let(:page)            { 1 }
        let(:page_size)       { 2 }
        let(:notes_expected) { user_notes.first(2) }
        let(:expected) do
          ActiveModel::Serializer::CollectionSerializer.new(notes_expected,
                                                            serializer: IndexNoteSerializer).to_json
        end

        before do
          expected
          get :index, params: { page: page, page_size: page_size }
        end

        it 'responds with the expected notes' do
          expect(response_body.to_json).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching reviews using filters' do
        let(:note_type) { 'review' }

        it_behaves_like 'fetch filtered'
      end

      context 'when fetching critiques using filters' do
        let(:note_type) { 'critique' }

        it_behaves_like 'fetch filtered'
      end

      context 'when fetching notes with sorting' do
        let(:notes_asc) { [create(:note, user: user, utility: user.utility, created_at: 1.day.ago)] + [create(:note, user: user, utility: user.utility)] }
        let(:notes_desc) { notes_asc.reverse }
        let(:expected_asc) do
          ActiveModel::Serializer::CollectionSerializer.new(notes_asc, serializer: IndexNoteSerializer).to_json
        end
        let(:expected_desc) do
          ActiveModel::Serializer::CollectionSerializer.new(notes_desc, serializer: IndexNoteSerializer).to_json
        end

        context 'when ordering ASC' do
          before do
            expected_asc
            get :index, params: { order: 'asc' }
          end

          it 'responds with notes in ascending order' do
            expect(response_body.to_json).to eq(expected_asc)
          end

          it 'responds with 200 status' do
            expect(response).to have_http_status(:ok)
          end
        end

        context 'when ordering DESC' do
          before do
            expected_desc
            get :index, params: { order: 'desc' }
          end

          it 'responds with notes in descending order' do
            expect(response_body.to_json).to eq(expected_desc)
          end

          it 'responds with 200 status' do
            expect(response).to have_http_status(:ok)
          end
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

        before { get :show, params: { id: note.id } }

        it 'responds with the note json' do
          expect(response.body).to eq(expected)
        end

        it 'responds with 200 status' do
          expect(response).to have_http_status(:ok)
        end
      end

      context 'when fetching a invalid note' do
        before { get :show, params: { id: Faker::Number.number } }

        it 'responds with 404 status' do
          expect(response).to have_http_status(:not_found)
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

      context 'when creating a note' do
        let(:params_create) { { note: { title: Faker::Lorem.sentence, content: Faker::Lorem.sentence, type: 'critique' } } }
        let(:note_count) { Note.count }

        before do
          note_count
          post :create, params: params_create
        end

        it 'responds with 201 status' do
          expect(response).to have_http_status(:created)
        end

        it 'creates a new note in the database' do
          expect(Note.count).to be(note_count + 1)
          created_note = Note.last
          expect(created_note.title).to eq(params_create[:note][:title])
          expect(created_note.content).to eq(params_create[:note][:content])
          expect(created_note.note_type).to eq('critique')
          expect(created_note.user).to eq(user)
        end
      end

      context 'when creating a note without note' do
        before do
          post :create
        end

        it 'responds with 400 status' do
          expect(response).to have_http_status(:bad_request)
        end
      end

      context 'when creating a note without title' do
        let(:params_create) { { note: { content: Faker::Lorem.sentence, type: 'critique' } } }

        it_behaves_like 'creating missing parameters'
      end

      context 'when creating a note without type' do
        let(:params_create) { { note: { content: Faker::Lorem.sentence, title: Faker::Lorem.sentence } } }

        it_behaves_like 'creating missing parameters'
      end

      context 'when creating a note without content' do
        let(:params_create) { { note: { type: 'critique', title: Faker::Lorem.sentence } } }

        it_behaves_like 'creating missing parameters'
      end

      context 'when creating with invalid type' do
        let(:params_create) { { note: { type: 'cat', title: Faker::Lorem.sentence, content: Faker::Lorem.sentence(word_count: 100) } } }

        before do
          post :create, params: params_create
        end

        it 'responds with 422 status' do
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when creating a review too long' do
        let(:params_create) { { note: { type: 'review', title: Faker::Lorem.sentence, content: Faker::Lorem.sentence(word_count: 100) } } }

        before do
          post :create, params: params_create
        end

        it 'responds with 422 status' do
          expect(response).to have_http_status(:unprocessable_entity)
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
