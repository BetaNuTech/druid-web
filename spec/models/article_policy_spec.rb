require 'rails_helper'

RSpec.describe ArticlePolicy do
  include_context "users"

  describe "policy" do
    describe "allowed params for a new article" do

      let(:article_params) { Article::ALLOWED_PARAMS }

      describe "for administrators" do
        it "should allow all params" do
          policy = ArticlePolicy.new(administrator, Article)
          expect(policy.allowed_params).to eq(article_params)
        end
      end

      describe "for corporate users" do
        it "should allow all params" do
          policy = ArticlePolicy.new(corporate, Article)
          expect(policy.allowed_params).to eq(article_params)
        end
      end

      describe "for managers" do
        it "should allow all params" do
          policy = ArticlePolicy.new(manager, Article)
          expect(policy.allowed_params).to eq(article_params)
        end
      end

      describe "for agents" do
        it "should allow all params" do
          policy = ArticlePolicy.new(manager, Article)
          expect(policy.allowed_params).to eq(article_params)
        end
      end
    end
  end

  describe "scope" do
    let(:all_article) { create(:article, audience: 'all') }
    let(:administrators_article) { create(:article, audience: 'administrator') }
    let(:administrator_article) { create(:article, user: administrator, audience: 'private')}
    let(:corporates_article) { create(:article, audience: 'corporate') }
    let(:corporate_article) { create(:article, user: corporate, audience: 'private') }
    let(:managers_article) { create(:article, audience: 'manager') }
    let(:manager_article) { create(:article, user: manager, audience: 'private') }
    let(:agent_article) { create(:article, user: agent, audience: 'private') }

    before do
      all_article
      administrator_article
      administrators_article
      corporates_article
      corporate_article
      managers_article
      manager_article
      agent_article
    end

    it "should allow administrators to see all articles" do
      expect(Article.count).to eq(8)
      policy = ArticlePolicy::Scope.new(administrator, Article)
      expect(policy.resolve.count).to eq(8)
    end

    it "should allow corporate to see corporate and general access articles and their own articles" do
      expect(Article.count).to eq(8)
      policy = ArticlePolicy::Scope.new(corporate, Article)
      expect(policy.resolve.count).to eq(8)
    end

    it "should allow managers to see manager and general access articles and their own articles" do
      expect(Article.count).to eq(8)
      policy = ArticlePolicy::Scope.new(manager, Article)
      expect(policy.resolve.count).to eq(3)
    end

    it "should allow agents to only see general access articles and their own articles"

  end
end
