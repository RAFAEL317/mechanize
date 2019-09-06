defmodule Mechanizex.Browser.HTTPShortcutsTest do
  alias Mechanizex.Browser
  import TestHelper

  defmacro __using__(_) do
    [:get, :delete, :options, :patch, :post, :put, :head]
    |> Enum.map(fn method ->
      quote do
        test "#{unquote(method)} delegate to request", %{bypass: bypass, browser: browser} do
          Bypass.expect_once(bypass, fn conn ->
            assert conn.method == unquote(method |> Atom.to_string() |> String.upcase())
            assert %{"lero" => "lero"} = Plug.Conn.fetch_query_params(conn).params
            assert [{"accept", "lero"} | _] = conn.req_headers

            Plug.Conn.resp(conn, 200, "OK PAGE")
          end)

          apply(Browser, unquote(:"#{method}!"), [
            browser,
            endpoint_url(bypass),
            [{"lero", "lero"}],
            [{"accept", "lero"}]
          ])
        end

        test "#{unquote(method)}! delegate to request", %{bypass: bypass, browser: browser} do
          Bypass.down(bypass)

          assert_raise Mechanizex.HTTPAdapter.NetworkError, fn ->
            apply(Browser, unquote(:"#{method}!"), [
              browser,
              endpoint_url(bypass),
              [{"lero", "lero"}],
              [{"accept", "lero"}]
            ])
          end
        end
      end
    end)
  end
end

defmodule Mechanizex.BrowserTest do
  use ExUnit.Case, async: true
  use Mechanizex.Browser.HTTPShortcutsTest
  alias Mechanizex.{HTTPAdapter, Request, Page, Browser}
  import TestHelper
  doctest Mechanizex.Browser

  setup do
    {:ok, %{bypass: Bypass.open(), browser: Browser.new()}}
  end

  setup_all do
    {:ok, default_ua: Browser.user_agent_string(:mechanizex)}
  end

  describe ".new" do
    test "start a process", %{browser: browser} do
      assert is_pid(browser)
    end
  end

  describe ".start_link" do
    test "start a process" do
      {:ok, browser} = Mechanizex.Browser.start_link()
      assert is_pid(browser)
    end

    test "start a different browser on each call" do
      {:ok, browser1} = Browser.start_link()
      {:ok, browser2} = Browser.start_link()

      refute browser1 == browser2
    end
  end

  describe "initial headers config" do
    test "load headers from mix config", %{browser: browser, default_ua: ua} do
      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua}
             ]
    end

    test "init parameters overrides mix config", %{default_ua: ua} do
      browser = Browser.new(http_headers: [{"custom-header", "value"}])

      assert Browser.http_headers(browser) == [
               {"custom-header", "value"},
               {"user-agent", ua}
             ]
    end

    test "ensure headers are always in downcase", %{default_ua: ua} do
      browser = Browser.new(http_headers: [{"Custom-Header", "value"}])

      assert Browser.http_headers(browser) == [
               {"custom-header", "value"},
               {"user-agent", ua}
             ]
    end
  end

  describe ".set_http_headers" do
    test "set all headers at once", %{browser: browser} do
      Browser.set_http_headers(browser, [{"content-type", "text/html"}])
      assert Browser.http_headers(browser) == [{"content-type", "text/html"}]
    end

    test "ensure all headers are in lowercase", %{browser: browser} do
      Browser.set_http_headers(browser, [
        {"Content-Type", "text/html"},
        {"Custom-Header", "Lero"}
      ])

      assert Browser.http_headers(browser) == [
               {"content-type", "text/html"},
               {"custom-header", "Lero"}
             ]
    end
  end

  describe ".put_http_header" do
    test "updates existent header", %{browser: browser} do
      Browser.put_http_header(browser, "user-agent", "Lero")

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", "Lero"}
             ]
    end

    test "add new header if doesnt'", %{browser: browser, default_ua: ua} do
      Browser.put_http_header(browser, "content-type", "text/html")

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua},
               {"content-type", "text/html"}
             ]
    end

    test "ensure inserted header is lowecase", %{browser: browser, default_ua: ua} do
      Browser.put_http_header(browser, "Content-Type", "text/html")

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", ua},
               {"content-type", "text/html"}
             ]
    end
  end

  describe ".http_header" do
    test "default user agent" do
    end
  end

  describe ".set_user_agent_alias" do
    test "set by alias", %{browser: browser} do
      Browser.set_user_agent_alias(browser, :windows_chrome)

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", Browser.user_agent_string(:windows_chrome)}
             ]
    end

    test "set on init" do
      browser = Browser.new(user_agent_alias: :windows_chrome)

      assert Browser.http_headers(browser) == [
               # loaded by config env
               {"foo", "bar"},
               {"user-agent", Browser.user_agent_string(:windows_chrome)}
             ]
    end

    test "raise error when invalid alias passed", %{browser: browser} do
      assert_raise ArgumentError, ~r/Invalid user agent/, fn ->
        Browser.set_user_agent_alias(browser, :lero)
      end
    end
  end

  describe ".http_adapter" do
    test "configure on init" do
      {:ok, browser} = Browser.start_link(http_adapter: :custom)
      assert Browser.http_adapter(browser) == Mechanizex.HTTPAdapter.Custom
    end

    test "default http adapter" do
      browser = Browser.new()
      assert Browser.http_adapter(browser) == HTTPAdapter.Httpoison
    end
  end

  describe ".set_http_adapter" do
    test "returns browser", %{browser: browser} do
      assert Browser.set_http_adapter(browser, Mechanizex.HTTPAdapter.Custom) == browser
    end

    test "updates http adapter", %{browser: browser} do
      Browser.set_http_adapter(browser, Mechanizex.HTTPAdapter.Custom)
      assert Browser.http_adapter(browser) == Mechanizex.HTTPAdapter.Custom
    end
  end

  describe ".set_html_parser" do
    test "returns mechanizex browser", %{browser: browser} do
      assert Browser.set_html_parser(browser, Mechanizex.HTMLParser.Custom) == browser
    end

    test "updates html parser", %{browser: browser} do
      Browser.set_html_parser(browser, Mechanizex.HTMLParser.Custom)
      assert Browser.html_parser(browser) == Mechanizex.HTMLParser.Custom
    end

    test "html parser option" do
      {:ok, browser} = Browser.start_link(html_parser: :custom)
      assert Browser.html_parser(browser) == Mechanizex.HTMLParser.Custom
    end
  end

  describe ".request!" do
    test "get request content", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, "GET", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "OK PAGE")
      end)

      page =
        Browser.request!(browser, %Request{
          method: :get,
          url: endpoint_url(bypass)
        })

      assert Page.body(page) == "OK PAGE"
    end

    test "send correct methods", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, "GET", "/", fn conn ->
        assert conn.method == "GET"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass)
      })

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        assert conn.method == "POST"
        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :post,
        url: endpoint_url(bypass)
      })
    end

    test "merge header with browser's default headers", %{bypass: bypass, browser: browser, default_ua: ua} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.req_headers == [
                 {"custom-header", "lero"},
                 # the header "foo" comes from config/test.exs
                 {"foo", "bar"},
                 {"host", "localhost:#{bypass.port}"},
                 {"user-agent", ua}
               ]

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        headers: [{"custom-header", "lero"}]
      })
    end

    test "ignore case on update default http header", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.req_headers == [
                 {"custom-header", "lero"},
                 # the header "foo" comes from config/test.exs
                 {"foo", "bar"},
                 {"host", "localhost:#{bypass.port}"},
                 {"user-agent", "Gustabot"}
               ]

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        headers: [{"custom-header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "ensure downcase of request headers", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, fn conn ->
        assert conn.req_headers == [
                 {"custom-header", "lero"},
                 # the header "foo" comes from config/test.exs
                 {"foo", "bar"},
                 {"host", "localhost:#{bypass.port}"},
                 {"user-agent", "Gustabot"}
               ]

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        headers: [{"Custom-Header", "lero"}, {"User-Agent", "Gustabot"}]
      })
    end

    test "send request parameters", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, fn conn ->
        assert Plug.Conn.fetch_query_params(conn).params == %{
                 "query" => "lero",
                 "start" => "100"
               }

        Plug.Conn.resp(conn, 200, "OK")
      end)

      Browser.request!(browser, %Request{
        method: :get,
        url: endpoint_url(bypass),
        params: [{"query", "lero"}, {"start", "100"}]
      })
    end

    test "ensure downcase of response headers", %{bypass: bypass, browser: browser} do
      Bypass.expect_once(bypass, fn conn ->
        conn
        |> Plug.Conn.merge_resp_headers([{"Custom-Header", "lero"}, {"FOO", "BAR"}])
        |> Plug.Conn.resp(200, "OK")
      end)

      page =
        Browser.request!(browser, %Request{
          method: :get,
          url: endpoint_url(bypass)
        })

      assert [{"custom-header", "lero"}, {"foo", "BAR"} | _] = page.response.headers
    end

    test "raise error when connection fail", %{bypass: bypass, browser: browser} do
      Bypass.down(bypass)

      assert_raise Mechanizex.HTTPAdapter.NetworkError, fn ->
        Browser.request!(browser, %Request{
          method: :get,
          url: endpoint_url(bypass)
        })
      end
    end
  end
end
