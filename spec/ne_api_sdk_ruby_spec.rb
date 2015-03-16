require 'spec_helper'
require 'feature_helper'

describe NeApiSdkRuby do
  it 'has a version number' do
    expect(NeApiSdkRuby::VERSION).not_to be nil
  end

  describe "各種APIを操作を実行する" do
    context "まだログインしていない場合" do
      it "ネクストエンジンログイン画面にリダイレクトされる" do
        visit "/#{SampleApp::END_POINT}"
        expect(page).to have_content 'Copyright 2007-2015 next-engine powered by Hamee Corp.'
      end
    end

    context "既にログインしている場合" do
      before :all do
        visit "https://base.next-engine.org/users/sign_in/"
        if page.body.include?('Copyright 2007-2015 next-engine powered by Hamee Corp.')
          fill_in('user[login_code]', :with => ENV['LOGIN_CODE'])
          fill_in('user[password]', :with => ENV['PASSWORD'])
          click_button('ログイン')
        end
      end

      after(:all) do
        visit "https://base.next-engine.org/"
        click_link('ログアウト')
      end

      it "APIサーバに接続済みになる" do
        visit "/#{SampleApp::END_POINT}"
        expect(page).to have_content 'APIサーバに接続済'
      end

      it "NEログインのみ実施し、利用者の基本情報を取得する" do
        visit "/#{SampleApp::END_POINT}/login_only"
        expect(page).to have_content 'company_ne_id'
      end

      it "契約企業一覧を取得するサンプルを実行する" do
        visit "/#{SampleApp::END_POINT}/api_find/company"
        expect(page).to have_content 'company_id'
      end

      it "利用者情報を取得するサンプルを実行する" do
        visit "/#{SampleApp::END_POINT}/api_find/user"
        expect(page).to have_content 'pic_name'
      end

      it "商品マスタ情報を取得するサンプルを実行する" do
        visit "/#{SampleApp::END_POINT}/api_find/goods"
        expect(page).to have_content '"count":"0"'
      end
    end
  end
end
