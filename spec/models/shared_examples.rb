shared_examples 'critique for utility' do |utility_factory, short_threshold, medium_threshold|
  let(:utility) { create(utility_factory) }

  it 'is valid' do
    note = create(:note, utility: utility)
    expect(note).to be_valid
  end

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

shared_examples 'review for utility' do |utility_factory, short_threshold|
  let(:utility) { create(utility_factory) }

  it 'is valid' do
    note = create(:note, :review, utility: utility)
    expect(note).to be_valid
  end

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
