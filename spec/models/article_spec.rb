require 'rails_helper'

RSpec.describe Article, type: :model do
  include_context "users"

  let(:article) { build(:article) }

  it "can be initialized" do
    article
  end

  it "can be saved" do
    assert article.save
  end

  describe "callbacks" do
    it "sets the slug on create" do
      article.title = "Testing 123"
      article.save
      expect(article.slug).to eq("testing-123")

      # It will not overwrite an existing slug
      article2 = build(:article)
      article2.slug = '123'
      article2.save
      expect(article2.slug).to eq('123')
    end
  end

  describe "validations" do
    describe "on articletype based on user role" do
      let(:article) { build(:article) }

      it "allows administrators to create any type of article" do
        article.user = administrator
        Article.articletypes.each do |articletype|
          article.articletype = articletype
          assert article.valid?
        end
      end

      it "allows corporate to create any type of article" do
        article.user = corporate
        Article.articletypes.each do |articletype|
          article.articletype = articletype
          assert article.valid?
        end
      end

      it "allows managers to create only help articles" do
        article.user = manager
        article.articletype = 'news'
        refute article.valid?
        article.articletype = 'blog'
        refute article.valid?
        article.articletype = 'tooltip'
        refute article.valid?
        article.articletype = 'help'
        assert article.valid?
      end

      it "allows agents to create only help articles" do
        article.user = agent
        article.articletype = 'news'
        refute article.valid?
        article.articletype = 'blog'
        refute article.valid?
        article.articletype = 'tooltip'
        refute article.valid?
        article.articletype = 'help'
        assert article.valid?
      end
    end
  end

  describe "on audience based on user role" do
    let(:article) { build(:article) }

    it "allows administrators to create an article for any audience" do
      article.user = administrator
      Article.audiences.each do |audience|
        article.audience = audience
        assert article.valid?
      end
    end

    it "allows corporate to create an article for any audience" do
      article.user = corporate
      Article.audiences.each do |audience|
        article.audience = audience
        assert article.valid?
      end
    end

    it "allows managers to create an article for manager, property, and all audiences" do
      article.user = manager
      article.audience = 'administrator'
      refute article.valid?
      article.audience = 'corporate'
      refute article.valid?
      article.audience = 'manager'
      assert article.valid?
      article.audience = 'property'
      assert article.valid?
      article.audience = 'all'
      assert article.valid?
    end

    it "allows agents to create an article for property and all audience" do
      article.user = agent
      article.audience = 'administrator'
      refute article.valid?
      article.audience = 'corporate'
      refute article.valid?
      article.audience = 'manager'
      refute article.valid?
      article.audience = 'property'
      assert article.valid?
      article.audience = 'all'
      assert article.valid?
    end
  end

end
