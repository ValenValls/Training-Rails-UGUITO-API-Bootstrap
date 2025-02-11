require 'rails_helper'

shared_examples 'critique for utility' do
  it 'has the correct type' do
    note = create(:note, utility: utility)
    expect(note.note_type).to eq('critique')
  end

  describe '#word_count' do
    it 'has correct word count' do
      note = create(:note, utility: utility, sentece_word_count: 34)
      expect(note.word_count).to be(34)
    end
  end

  describe '#content_length' do
    it 'has short length if short' do
      note = create(:note, utility: utility, sentece_word_count: short_threshold)
      expect(note.content_length).to eq('short')
    end

    it 'has medium length if medium' do
      note = create(:note, utility: utility, sentece_word_count: medium_threshold)
      expect(note.content_length).to eq('medium')
    end

    it 'has long length if long' do
      note = create(:note, utility: utility, sentece_word_count: medium_threshold + 1)
      expect(note.content_length).to eq('long')
    end
  end
end

shared_examples 'review for utility' do
  it 'has the correct type' do
    note = create(:note, :review, utility: utility)
    expect(note.note_type).to eq('review')
  end

  describe '#word_count' do
    it 'has correct word count' do
      note = create(:note, :review, utility: utility, sentece_word_count: 34)
      expect(note.word_count).to be(34)
    end
  end

  it 'is short' do
    note = create(:note, utility: utility, sentece_word_count: short_threshold)
    expect(note.content_length).to eq('short')
  end

  it 'does not allow longer content' do
    note = build(:note, :review, utility: utility, sentece_word_count: short_threshold + 1)
    expect { note.save! }.to raise_error ActiveRecord::RecordInvalid
  end
end

describe Note, type: :model do
  context 'when creating' do
    subject(:note) { build(:note) }

    it { is_expected.to validate_presence_of(:content) }

    it { is_expected.to validate_presence_of(:note_type) }

    it { is_expected.to validate_presence_of(:title) }

    it { is_expected.to belong_to :utility }

    it { is_expected.to belong_to :user }

    it 'has a valid factory' do
      expect(create(:note)).to be_valid
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
    let(:utility) { create(:north_utility) }
    let(:short_threshold) { 50 }
    let(:medium_threshold) { 100 }

    it_behaves_like 'critique for utility'
  end

  context 'when creating a critique for south' do
    let(:utility) { create(:south_utility) }
    let(:short_threshold) { 60 }
    let(:medium_threshold) { 120 }

    it_behaves_like 'critique for utility'
  end

  context 'when creating a review for north' do
    let(:utility) { create(:north_utility) }
    let(:short_threshold) { 50 }

    it_behaves_like 'review for utility'
  end

  context 'when creating a review for south' do
    let(:utility) { create(:south_utility) }
    let(:short_threshold) { 60 }

    it_behaves_like 'review for utility'
  end

  context 'when creating a review for another utility' do
    let(:utility) { create(:utility, short_word_count_threshold: 30, medium_word_count_threshold: 60) }
    let(:short_threshold) { 30 }

    it_behaves_like 'review for utility'
  end
end
