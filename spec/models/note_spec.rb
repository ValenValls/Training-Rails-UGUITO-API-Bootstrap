require 'rails_helper'
require 'models/shared_examples'
describe Note, type: :model do
  context 'when creating with factory' do
    subject(:note) do
      create(:note)
    end

    %i[utility_id user_id content note_type title].each do |value|
      it { is_expected.to validate_presence_of(value) }
    end

    it 'has a valid factory' do
      expect(subject).to be_valid
    end

    it 'has default world_count' do
      expect(subject.word_count).to be(4)
    end

    it 'has default length' do
      expect(subject.content_length).to eq('short')
    end
  end

  describe '#word_count' do
    it 'has correct word count' do
      note = create(:note, sentece_word_count: 34)
      expect(note.word_count).to be(34)
    end
  end

  context 'when creating a critique for north' do
    it_behaves_like 'critique for utility', :north_utility, 50, 100
  end

  context 'when creating a critique for south' do
    it_behaves_like 'critique for utility', :south_utility, 60, 120
  end

  context 'when creating a review for north' do
    it_behaves_like 'review for utility', :north_utility, 50
  end

  context 'when creating a review for south' do
    it_behaves_like 'review for utility', :south_utility, 60
  end
end
