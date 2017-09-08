
作成したwebサービスにスクリーンショットを追加したいと思ったことはありませんか？

Heroku に Headless Chromeを入れると Heroku内でChromeを操作できるので、簡単にスクショを取ることができます。
rubyからchromeを呼び出しでスクショをとってみます。

# Herokuをsetupする

Herokuでアプリを作成しましょう(作成手順は他を参考にしてください）。
作成時にはchromeが入っていないので、Buildpacksに追加します。HerokuコンソールのSettingにBuildpacksの設定があるので、２つ追加します。

https://github.com/heroku/heroku-buildpack-chromedriver.git
https://github.com/heroku/heroku-buildpack-google-chrome.git

<img width="1139" alt="スクリーンショット 2017-09-09 5.41.44.png" src="https://qiita-image-store.s3.amazonaws.com/0/25071/edf125fd-6028-86dd-dbcf-ba655f7b7baf.png">

追加後にデプロイをすると、デプロイ時に関連するパッケージがインストールされます。

# Rubyからchromeを呼び出してスクリーンショットをとる

ruby からはcapybaraとseleniumを使ってchromeを呼び出します。
Gemfileに追加してbundle installします。

```ruby
gem 'capybara'
gem "selenium-webdriver"
```

コードの流れは、chromeの設定をしてsessionを作成、sessionでurlを指定してwebページを訪れ、そこでスクショをとります。
session.visit後に少し待たないとchromeが画面をrenderする前のスクショがとれる場合があるのでまっています。

```ruby
    require 'capybara'
    require 'selenium-webdriver'
    
    base_args = %w{headless no-sandbox disable-gpu}

    chrome_bin =  "/app/.apt/usr/bin/google-chrome"
    chrome_opts = chrome_bin ? { "chromeOptions" => { "binary" => chrome_bin, 'args' => base_args } } : {}

    Capybara.register_driver :chrome do |app|
      Capybara::Selenium::Driver.new(
        app,
        browser: :chrome,
        desired_capabilities: Selenium::WebDriver::Remote::Capabilities.chrome(chrome_opts)
      )
    end

    Capybara.default_driver = :chrome

    @session = Capybara::Session.new(:chrome)

    @session.visit(url)
    sleep 5 # waiting for getting assets                                                                                                                                                                

    @session.driver.browser.manage.window.move_to(0, 0)
    @session.driver.browser.manage.window.resize_to(800, 1200)
    sleep 1

    @session.save_screenshot(cache_file)
    @session.driver.quit

```

# 日本語 font
Herokuの環境では標準では日本語フォントが表示されないため、文字が化けます。フォントを用意する必要があります。herokuはfontconfigに対応しているため、ソースの直下に.fontsを作成して、そこにttsのフォントをおくとそのフォントが使われます。 http://okoneya.jp/font/ で配布しているフォントを使いました。

# ソース
sinatraに組み込んだソース一式をこちらに置いておきます。

https://github.com/isamu/heroku-screenshot

# Herokuで確認
完成したものをこちらにデプロイしています。qiita上のページに限定してスクショをとるようにしています。urlを変更すれば、他のページのスクショも取れます。

https://heroku-screenshot.herokuapp.com/thumbnail?url=http://qiita.com/isamua/items/c6a2f2ae5e2b03ebca6e

![thumbnail.png](https://qiita-image-store.s3.amazonaws.com/0/25071/310ae45f-7569-8930-f226-076a6f1a4d04.png)

