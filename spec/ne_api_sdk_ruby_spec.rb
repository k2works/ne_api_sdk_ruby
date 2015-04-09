require 'spec_helper'

CLIENT_ID = ENV['NE_API_CLIENT_ID']
CLIENT_SECRET = ENV['NE_API_CLIENT_SECRET']

describe NeApiSdkRuby do
  it 'has a version number' do
    expect(NeApiSdkRuby::VERSION).not_to be nil
  end

  describe "NEログインのみ実施し、利用者の基本情報を取得する" do
    let(:client) do
      redirect_uri = 'https://localhost:8088/ne_api_sdk_ruby/login_only'
      NeApiSdkRuby::NeApiClient.new(CLIENT_ID, CLIENT_SECRET,redirect_uri)
    end
    context "既にログインしている場合" do
      let(:login) { client.neLogin }

      # ログイン後の基本情報を返却する
      it "access_tokenを含む" do
        expect(login['access_token']).to_not be_nil
      end

      it "company_app_headerを含む" do
        expect(login['company_app_header']).to_not be_nil
      end

      it "company_ne_idを含む" do
        expect(login['company_ne_id']).to_not be_nil
      end

      it "company_nameを含む" do
        expect(login['company_name']).to_not be_nil
      end

      it "company_kanaを含む" do
        expect(login['company_kana']).to_not be_nil
      end

      it "uidを含む" do
        expect(login['uid']).to_not be_nil
      end

      it "pic_ne_idを含む" do
        expect(login['pic_ne_id']).to_not be_nil
      end

      it "pic_nameを含む" do
        expect(login['pic_name']).to_not be_nil
      end

      it "pic_kanaを含む" do
        expect(login['pic_kana']).to_not be_nil
      end

      it "pic_mail_addressを含む" do
        expect(login['pic_mail_address']).to_not be_nil
      end

      it "refresh_tokenを含む" do
        expect(login['refresh_token']).to_not be_nil
      end

      it "resultを含む" do
        expect(login['result']).to_not be_nil
      end
    end
    context "まだログインしていない場合" do
      it "ネクストエンジンログイン画面にリダイレクトされる"
    end
    context "正しくログインした場合" do
      it "$redirect_uriにリダイレクトされる"
    end
    context "リダイレクト先で、再度neLoginを呼ぶ" do
      it "ログイン後の基本情報を返却する"
    end
  end

end
