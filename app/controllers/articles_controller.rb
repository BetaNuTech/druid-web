class ArticlesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_article, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized

  # GET /articles
  # GET /articles.json
  def index
    authorize Article
    @search = ArticleSearch.new(params: params.permit!, skope: article_scope)
    @articles = @search.search
  end

  # GET /articles/1
  # GET /articles/1.json
  def show
    authorize @article
  end

  # GET /articles/new
  def new
    if params[:article].present?
      @article = Article.new(article_params)
    else
      @article = Article.new
    end
    @article.user = current_user
    authorize @article
  end

  # GET /articles/1/edit
  def edit
    authorize @article
  end

  # POST /articles
  # POST /articles.json
  def create
    @article = Article.new(article_params)
    @article.user = current_user
    authorize @article

    respond_to do |format|
      if @article.save
        format.html { redirect_to @article, notice: 'Article was successfully created.' }
        format.json { render :show, status: :created, location: @article }
      else
        format.html { render :new }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /articles/1
  # PATCH/PUT /articles/1.json
  def update
    authorize @article
    respond_to do |format|
      if @article.update(article_params)
        format.html { redirect_to @article, notice: 'Article was successfully updated.' }
        format.json { render :show, status: :ok, location: @article }
      else
        format.html { render :edit }
        format.json { render json: @article.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /articles/1
  # DELETE /articles/1.json
  def destroy
    authorize @article
    @article.destroy
    respond_to do |format|
      format.html { redirect_to articles_url, notice: 'Article was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_article
      @article = article_scope.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def article_params
      allowed_params = policy(@article||Article).allowed_params
      params.require(:article).permit(*allowed_params)
    end

    def article_scope
      policy_scope(Article)
    end
end
