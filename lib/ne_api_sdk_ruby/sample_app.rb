require 'sinatra/base'
require 'sinatra/reloader'
require 'pp'
require 'dotenv'
Dotenv.load

CLIENT_ID = ENV['NE_API_CLIENT_ID']
CLIENT_SECRET = ENV['NE_API_CLIENT_SECRET']
END_POINT = 'ne_api_sdk_ruby'
REDIRECT_URL = 'https://localhost:8088/' + END_POINT

class SampleApp  < Sinatra::Base
  configure :development do
    register Sinatra::Reloader
  end
  enable :sessions
  set :client, NeApiSdkRuby::NeApiClient.new(CLIENT_ID, CLIENT_SECRET,REDIRECT_URL)

  get "/#{END_POINT}" do
    session[:uid] = params['uid']
    session[:state] = params['state']

    if session['uid'].nil? and session['state'].nil?
      pp 'APIサーバに未接続'
      login
    else
      pp 'APIサーバに接続済'
    end
  end

  get "/#{END_POINT}/login_only" do
    response = login
    response.to_json
  end

  get "/#{END_POINT}/api_find/company" do
    #////////////////////////////////////////////////////////////////////////////////
    #// 契約企業一覧を取得するサンプル
    #////////////////////////////////////////////////////////////////////////////////
    under_contract_company = client.apiExecuteNoRequiredLogin('/api_app/company')
    under_contract_company.to_json
  end

  get "/#{END_POINT}/api_find/user" do
    #////////////////////////////////////////////////////////////////////////////////
    #// 利用者情報を取得するサンプル
    #////////////////////////////////////////////////////////////////////////////////
    user = client.apiExecute(session['uid'],session['state'],'/api_v1_login_user/info')
    user.to_json
  end

  get "/#{END_POINT}/api_find/goods" do
    #////////////////////////////////////////////////////////////////////////////////
    #// 商品マスタ情報を取得するサンプル
    #////////////////////////////////////////////////////////////////////////////////
    query = {}
    # 検索結果のフィールド：商品コード、商品名、商品区分名、在庫数、引当数、フリー在庫数
    query['fields'] = 'goods_id, goods_name, goods_type_name, stock_quantity, stock_allocation_quantity, stock_free_quantity'
    # 検索条件：商品コードがredで終了している、かつ商品マスタの作成日が2013/10/31の20時より前
    query['goods_id-like'] = '%red'
    query['goods_creation_date-lt'] = '2013-10-31 20:00:00'
    # 検索は0～50件まで
    query['offset'] = '0'
    query['limit'] = '50'

    # アクセス制限中はアクセス制限が終了するまで待つ。
    # (1以外/省略時にアクセス制限になった場合はエラーのレスポンスが返却される)
    query['wait_flag'] = '1'

    # 検索対象の総件数を取得
    goods_cnt = client.apiExecute(session['uid'],session['state'],'/api_v1_master_goods/count', query)
    # 検索実行
    goods = client.apiExecute(session['uid'],session['state'],'/api_v1_master_goods/search', query)

    goods.to_json
  end

  helpers do
    def client
      settings.client
    end

    def login
      if session['uid'].nil? and session['state'].nil?
        response = client.neLogin
        case response['result']
          when NeApiSdkRuby::NeApiClient::RESULT_SUCCESS
            p 'ログインしました'
          when NeApiSdkRuby::NeApiClient::RESULT_REDIRECT
            redirect response
          when NeApiSdkRuby::NeApiClient::RESULT_ERROR
            p 'ログインエラーが発生しました'
          else
            redirect response
        end
      else
        client.neLogin(session['uid'],session['state'])
      end
    end
  end
end