class ArticlesController < ApplicationController
    # Controlando acciones con CallBacks
    # before_action :validate_user, except: [:show, :index]
    before_action :authenticate_user!, only: [:create, :new]
    # Con este otro eliminamos codigo repetido, DRY
    before_action :set_article, except: [:index, :new, :create]
    # Para otorgar permisos al usuario logeado de acuerdo a el campo permission_level
    before_action :authenticate_editor!, only: [:new, :create, :update]
    before_action :authenticate_admin!, only: [:destroy, :publish]

    # GET /articles
    def index
        # Variable de clase Vista y Controlador con todos los registros
        # pero ahora utilizando el filtro de los scopes declarados en el modelo
        # @articles = Article.publicados.ultimos
        # Ahora paginamos el resultado de los filtros anteriores
        @articles = Article.paginate(page: params[:page], per_page: 10).publicados.ultimos

    end
    # GET /articles/:id
    def show
        # Encontrar un registro por ID
        @article = Article.find(params[:id])
        # Esto es lo mismo que la linea anterior pero ahorrando codigo ya que se repetia en los demas metodos
        @article.update_visits_count

        @comment = Comment.new


        # Usando Where
        Article.where("id = ? OR title = ? ", params[:id], params[:title])
        # Porque NO usar interpolación de Cadenas, puede existir SQL Injection
        Article.where("id = #{params[:id]} ")
        # Diferente de
        Article.where.not("id = ? ", params[:id])
    end

    # GET /articles/new
    def new
        @article = Article.new
        @categories = Category.all
    end

    # POST /articles/:id/edit
    def edit
        # Encontrar un registro por ID
        @article = Article.find(params[:id])
    end

    # POST /articles
    def create
        # @article = Article.new(title: params[:article][:title], body: params[:article][:body])
        # Ahora lo mismo pero con StrongParams para indicar que campos son permitidos de tocar
        @article = current_user.articles.new(article_params)
        @article.categories = params[ :categories ]

        # Cualquiera de estas formas funciona para lo mismo
        # if @article.invalid?
        # if @article.valid?
        #     @article.save
        #     redirect_to @article
        # else
        #     render :new
        # end

        if @article.save
            redirect_to @article
        else
            render :new
        end

        # Bota un error para ver los parametros que le llegan al controlador desde el form
        # raise params.to_yaml
    end

    # PUT /articles/:id
    def update
        # Encontramos el Articulo a editar
        @article = Article.find(params[:id])

        # Se puede hacer con update o update_attributes
        # @article.update_attributes({title: 'Nuevo Titulo'})
        if @article.update(article_params)
            # Aplican las mismas reglas de StrongParams
            redirect_to @article
        else
            render :edit
        end

    end

    # DELETE /articles/:id
    def destroy
        @article = Article.find(params[:id])
        # Elimina el objeto de la BD
        @article.destroy

        redirect_to articles_path
    end

    def publish
        @article.publish!
        redirect_to @article
    end

    # Metodos privados
    private

    def set_article
        @article = Article.find(params[:id])
    end

    def validate_user
        redirect_to new_user_session_path, notice: "Necesita iniciar sesión!"
    end

    def article_params
        params.require(:article).permit(:title, :body, :cover, :categories, :markup_body)
    end

end
