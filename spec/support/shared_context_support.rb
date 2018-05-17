shared_context 'match expectations' do
  it 'fetches all articles with matching conditions' do
    expect(Article.accessible_by(@ability).to_a).to eq([accessible_article])
    expect(@ability).to be_able_to(:read, accessible_article)
    expect(@ability).not_to be_able_to(:read, not_accessible_article)
  end
end

shared_context 'rules with relation existance on relation' do
  before(:example) do
    @article2.mentions << Mention.create!
    @ability.send(rule_type, :manage, Article, published: false)
    @ability.send(rule_type, :read, Article, mentions: { user: nil })
  end
end

shared_context 'rule with relation existance' do
  before(:example) do
    @article2.mentions << Mention.create!
    @ability.send(rule_type, :read, Article, mentions: { user: nil })
    @ability.send(rule_type, :manage, Article, published: false)
  end
end

shared_context 'rules with relation existance on base model' do
  before(:example) do
    @ability.send(rule_type, :manage, Article, published: false)
    @ability.send(rule_type, :read, Article, mentions: nil)
  end
end
