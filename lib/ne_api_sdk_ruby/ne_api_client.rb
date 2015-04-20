#
# == Nextengine API SDK(http://api.next-e.jp/).
#
# Author:: K.Kakigi
# Version:: 0.1.0
# License:: Ruby License
require 'faraday'
require 'faraday_middleware'
require 'simple_oauth'
require 'uri'
require 'json'

module NeApiSdkRuby
  class NeApiClient
    # 利用するサーバーのURLのスキーム＋ホスト名の定義
    API_SERVER_HOST   = 'https://api.next-engine.org'
    NE_SERVER_HOST    = 'https://base.next-engine.org'

    # 認証に用いるURLのパスを定義
    # NEログイン
    PATH_LOGIN	= '/users/sign_in/'
    # API認証
    PATH_OAUTH	= '/api_neauth/'

    # APIのレスポンスの処理結果ステータスの定義
    # 成功
    RESULT_SUCCESS	= 'success'
    # 失敗
    RESULT_ERROR		= 'error'
    # 要リダイレクト
    RESULT_REDIRECT	= 'redirect'

    # APIの接続情報(initializeのヘッダーコメントを参照して下さい)
    # @!attribute [rw] access_token
    #  @return [String] アクセストークン
    attr_accessor :access_token
    # @!attribute [rw] refresh_token
    #  @return [String] リフレッシュトークン
    attr_accessor :refresh_token

    #
    # インスタンス生成時、実行環境に合わせた値を引数に指定して下さい。
    #
    # redirect_uriの説明：
    #   まだ認証していないユーザーがアクセスした場合(ネクストエンジンログインが必要な場合)、
    #   本SDKが自動的にネクストエンジンのログイン画面にリダイレクトします（ユーザーには認証画面が表示される）。
    #   ユーザーが認証した後、ネクストエンジンサーバーから認証情報と共にアプリケーションサーバーに
    #   リダイレクトします。その際のアプリケーションサーバーのリダイレクト先uriです。
    #
    # redirect_uriの省略又はNULL指定について：
    #   通常のWebアプリケーションの場合は、必ず指定して下さい。
    #   NULLにするのは、一度Webアプリケーションで認証した後、バッチ等で非同期にAPIを実行する場合のみです。
    #   NULLにし認証の有効期限が切れた場合(resultがRESULT_REDIRECT)、SDK内部で自動的にリダイレクトせず
    #   結果はredirectのまま正常終了しません（認証の有効期限が切れた場合は、再度Web経由で認証の必要あり）。
    #
    # access_tokenとrefresh_tokenの説明：
    #   バッチ等で非同期にAPIを実行する場合のみ、認証した状態を保持する為に必要です。
    #
    # access_tokenとrefresh_tokenの省略(NULL指定)について：
    #   通常のWebアプリケーションの場合は、省略して下さい。
    #   指定するのは、一度Webアプリケーションで認証した後、バッチ等で非同期にAPIを実行する場合のみです。
    #   指定する値は、最後にapiExecute又はneLogin呼び出し後の同名のメンバ変数の値です。
    #   この値を初回ログイン時などにDBに保存しておき、バッチではその値を元に処理を実行することを想定しています。
    # @note 注意：この値はユーザー毎(uid毎)に管理する必要があります。別のユーザーの値を指定してSDKを実行すると
    #		  他ユーザーの情報にアクセスしてしまうため、厳重にご注意をお願いします。
    #
    # @param	[string]	client_id		クライアントID。
    # @param	[string]	client_secret	クライアントシークレット。
    # @param	[string]	redirect_uri	ヘッダーコメント参照。
    # @param	[string]	access_token	同上。
    # @param	[string]	refresh_token	同上。
    # @return	void
    def initialize(client_id, client_secret, redirect_uri = nil, access_token = nil, refresh_token = nil)
      @client_id = client_id
      @client_secret = client_secret
      @redirect_uri = redirect_uri
      @access_token= access_token
      @refresh_token= refresh_token

      @conn = Faraday.new(:url => API_SERVER_HOST ) do |faraday|
        faraday.request  :url_encoded             # form-encode POST params
        faraday.response :logger                  # log requests to STDOUT
        faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      end
    end
    # ネクストエンジンログインを実施し、かつAPIを実行し、結果を返します。
    #
    # @param [string] uid アプリを起動したユーザーのuid
    # @param [string] state アプリを起動したユーザーのstate
    # @param [string]	path			呼び出すAPIのパスです。/から指定して下さい。
    # @param [array]	api_params		呼び出すAPIの必要に応じてパラメータ(連想配列)です。
    #									パラメータが不要な場合、省略又はNULLを指定して下さい。
    # @param [string]	redirect_uri	インスタンスを作成した後、リダイレクト先を変更したい
    #									場合のみ設定して下さい。
    # @return	array  実行結果。内容は呼び出したAPIにより異なります。
    def apiExecute(uid, state, path, api_params = {}, redirect_uri = nil)
      if !redirect_uri.nil?
        @redirect_uri = redirect_uri
      end

      if @access_token.nil?
        setUidAndState(uid,state)

        response = setAccessToken
        if response['result'] != RESULT_SUCCESS
          return response
        end
      end

      api_params['access_token'] = @access_token
      if !@refresh_token.nil?
        api_params['refresh_token'] = refresh_token
      end

      response = post(API_SERVER_HOST + path , api_params)

      if response['access_token']
        @access_token = response['access_token']
      end
      if response['refresh_token']
        @refresh_token = response['refresh_token']
      end

      responseCheck(response)
      return response
    end
    # ネクストエンジンログインが不要なAPIを実行します。
    #
    # @param [string] path			呼び出すAPIのパスです。/から指定して下さい。
    # @param [array]  api_params		呼び出すAPIの必要に応じてパラメータ(連想配列)です。
    #									パラメータが不要な場合、省略又はNULLを指定して下さい。
    #
    # @return	[array] 実行結果。内容は呼び出したAPIにより異なります。
    def apiExecuteNoRequiredLogin(path, api_params = {})
      api_params['client_id'] = @client_id
      api_params['client_secret'] = @client_secret

      response = post(API_SERVER_HOST + path, api_params)
      return response
    end
    # ネクストエンジンログインのみ実行します。
    # 既にログインしている場合、ログイン後の基本情報を返却します。
    # まだログインしていない場合、ネクストエンジンログイン画面にリダイレクトされ、
    # 正しくログインした場合、redirect_uriにリダイレクトされます。
    # リダイレクト先で、再度neLoginを呼ぶ事で、ログイン後の基本情報を返却します。
    #
    # @param [string] uid アプリを起動したユーザーのuid
    # @param [string] state アプリを起動したユーザーのstate
    # @param [string]	redirect_uri	インスタンスを作成した後、リダイレクト先を変更したい
    #									場合のみ設定して下さい。
    # @return [array] NE APIのログイン後の基本情報。
    def neLogin(uid = nil,state = nil,redirect_uri = nil)
      if @redirect_uri.nil?
        @redirect_uri = redirect_uri
      end

      setUidAndState(uid,state)

      if @uid.nil? or @state.nil?
        return redirectNeLogin
      else
        params = {uid: @uid, state: @state}

        response = post(API_SERVER_HOST + PATH_OAUTH, params)

        responseCheck(response)

        return response
      end
    end
    private
    #
    # 以下は全てSDKの内部処理用のメソッドです
    #
    def destruct

    end
    # メンバ変数にuidとstateを設定します。
    #
    # 1.NEからアプリを起動した場合。
    #	uidとstateがGETパラメータに渡ってくる為、メンバ変数に設定します。
    # 2.直接アプリを起動した場合。
    #	uidとstateがGETパラメータに渡ってこない為、NEに認証に行きます(NEサーバーへリダイレクト)。
    #	以下のようにユーザーの認証が終わると本サーバーにNEサーバーからリダイレクトされます。
    #	2.1.起動したユーザーが既にNEログイン済みの場合。
    #		認証画面を表示せずに$redirect_uriにリダイレクトされます。
    #	2.2.起動したユーザーがまだNEログインしていない場合。
    #		認証画面を表示して$redirect_uriにリダイレクトされます。
    #
    # @return	void
    def setUidAndState(uid,state)
      if !uid.nil?
        @uid = uid
      end
      if !state.nil?
        @state = state
      end
    end
    # メンバ変数にaccess_token(とあればrefresh_token)を設定します。
    #
    # @return	[array] access_token発行処理の実行結果。
    def setAccessToken
      params = {uid: @uid, state: @state}
      response = post(API_SERVER_HOST + PATH_OAUTH, params)
      if !responseCheck(response)
        return response
      end

      @access_token = response['access_token']
      if( response['refresh_token'])
        @refresh_token = response['refresh_token']
      end
      return response
    end

    def responseCheck(response)
      case response['result']
        when RESULT_ERROR
          return false
        when RESULT_REDIRECT
          if @redirect_uri.nil?
            return false
          else
            redirectNeLogin
          end
        when RESULT_SUCCESS
          return true
        else
          raise 'SDKで例外が発生しました。クライアントID・シークレットや指定したパスが正しいか確認して下さい'
      end
    end

    def redirectNeLogin
      params = {}
      params['client_id'] = @client_id
      params['client_secret'] = @client_secret
      params['redirect_uri'] = @redirect_uri
      url = NE_SERVER_HOST + PATH_LOGIN + '?' + getUrlParams(params)
      return url
    end

    def post(url, params)
      response = @conn.post url , params
      JSON.parse(response.body)
    end

    def getUrlParams(params)
      if params.nil?
        return
      end
      get_param = ''
      params.each do |k,v|
        if !v.nil?
          get_param << "&#{k}=" + URI.escape(v)
        end
      end
      return get_param.sub(/^&/,'')
    end
  end
end