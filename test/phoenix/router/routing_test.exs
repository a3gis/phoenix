defmodule Phoenix.Router.RoutingTest do
  use ExUnit.Case
  use PlugHelper

  defmodule UsersController do
    use Phoenix.Controller
    def index(conn, _params), do: text(conn, "users index")
    def show(conn, _params), do: text(conn, "users show")
    def top(conn, _params), do: text(conn, "users top")
    def crash(_conn, _params), do: raise "crash!"
    def options(conn, _params), do: text(conn, "users options")
    def connect(conn, _params), do: text(conn, "users connect")
    def head(conn, _params), do: conn |> send_resp(200, "")
    def trace(conn, _params), do: text(conn, "users trace")
    def not_found(conn, _params), do: text(conn, :not_found, "not found")
  end

  defmodule SessionsController do
    use Phoenix.Controller

    def new(conn, _params), do: text(conn, "session login")
    def create(conn, _params), do: text(conn, "session created")
    def destroy(conn, _params), do: text(conn, "session destroyed")
  end

  defmodule PostsController do
    use Phoenix.Controller
    def show(conn, _params), do: text(conn, "show posts")
    def new(conn, _params), do: text(conn, "new posts")
    def index(conn, _params), do: text(conn, "index posts")
    def create(conn, _params), do: text(conn, "create posts")
    def update(conn, _params), do: text(conn, "update posts")
  end

  defmodule FilesController do
    use Phoenix.Controller
    def show(conn, _params), do: text(conn, "#{conn.params["path"]}")
  end

  defmodule CommentsController do
    use Phoenix.Controller
    def show(conn, _params), do: text(conn, "show comments")
    def edit(conn, _params), do: text(conn, "edit comments")
    def index(conn, _params), do: text(conn, "index comments")
    def new(conn, _params), do: text(conn, "new comments")
    def create(conn, _params), do: text(conn, "create comments")
    def update(conn, _params), do: text(conn, "update comments")
    def destroy(conn, _params), do: text(conn, "destroy comments")
  end

  defmodule Router do
    use Phoenix.Router
    get "/", UsersController, :index, as: :users
    get "/users/top", UsersController, :top, as: :top
    get "/users/:id", UsersController, :show, as: :user
    get "/profiles/profile-:id", UsersController, :show
    get "/route_that_crashes", UsersController, :crash
    get "/files/:user_name/*path", FilesController, :show
    get "/backups/*path", FilesController, :show
    get "/static/images/icons/*image", FilesController, :show

    trace "/trace", UsersController, :trace
    options "/options", UsersController, :options
    connect "/connect", UsersController, :connect
    head "/head", UsersController, :head

    resources "comments", CommentsController
    resources "posts", PostsController, except: [ :destroy ]
    resources "sessions", SessionsController, only: [ :new, :create, :destroy ]

    get "/users/:user_id/comments/:id", CommentsController, :show
  end

  defmodule CatchAllRouter do
    use Phoenix.Router
    get "/users/top", UsersController, :top, as: :top
    get "/users/:id", UsersController, :show, as: :user
    get "/*path", UsersController, :not_found
  end

  test "get root path" do
    conn = simulate_request(Router, :get, "/")
    assert conn.status == 200
    assert conn.resp_body == "users index"
  end

  test "route to named param with dashes matches" do
    conn = simulate_request(Router, :get, "users/75f6306d-a090-46f9-8b80-80fd57ec9a41")
    assert conn.status == 200
    assert conn.resp_body == "users show"
    assert conn.params["id"] == "75f6306d-a090-46f9-8b80-80fd57ec9a41"

    conn = simulate_request(Router, :get, "users/75f6306d-a0/comments/34-95")
    assert conn.status == 200
    assert conn.resp_body == "show comments"
    assert conn.params["user_id"] == "75f6306d-a0"
    assert conn.params["id"] == "34-95"
  end

  test "get with named param" do
    conn = simulate_request(Router, :get, "users/1")
    assert conn.status == 200
    assert conn.resp_body == "users show"
    assert conn.params["id"] == "1"
  end

  test "get with multiple named params" do
    conn = simulate_request(Router, :get, "users/1/comments/2")
    assert conn.status == 200
    assert conn.resp_body == "show comments"
    assert conn.params["user_id"] == "1"
    assert conn.params["id"] == "2"
  end

  test "get to custom action" do
    conn = simulate_request(Router, :get, "users/top")
    assert conn.status == 200
    assert conn.resp_body == "users top"
  end

  test "get with resources to 'comments/new' maps to new action" do
    conn = simulate_request(Router, :get, "comments/new")
    assert conn.status == 200
    assert conn.resp_body == "new comments"
  end

  test "get with resources to 'comments' maps to index action" do
    conn = simulate_request(Router, :get, "comments")
    assert conn.status == 200
    assert conn.resp_body == "index comments"
  end

  test "get with resources to 'comments/123' maps to show action with named param" do
    conn = simulate_request(Router, :get, "comments/123")
    assert conn.status == 200
    assert conn.resp_body == "show comments"
    assert conn.params["id"] == "123"
  end

  test "get with resources to 'comments/123/edit' maps to edit action with named param" do
    conn = simulate_request(Router, :get, "comments/123/edit")
    assert conn.status == 200
    assert conn.resp_body == "edit comments"
    assert conn.params["id"] == "123"
  end

  test "post with resources to 'comments' maps to create action" do
    conn = simulate_request(Router, :post, "comments")
    assert conn.status == 200
    assert conn.resp_body == "create comments"
  end

  test "put with resources to 'comments/1' maps to update action" do
    conn = simulate_request(Router, :put, "comments/1")
    assert conn.status == 200
    assert conn.resp_body == "update comments"
    assert conn.params["id"] == "1"
  end

  test "patch with resources to 'comments/2' maps to update action" do
    conn = simulate_request(Router, :patch, "comments/2")
    assert conn.status == 200
    assert conn.resp_body == "update comments"
    assert conn.params["id"] == "2"
  end

  test "delete with resources to 'comments/2' maps to destroy action" do
    conn = simulate_request(Router, :delete, "comments/2")
    assert conn.status == 200
    assert conn.resp_body == "destroy comments"
    assert conn.params["id"] == "2"
  end

  test "options to custom action" do
    conn = simulate_request(Router, :options, "/options")
    assert conn.status == 200
    assert conn.resp_body == "users options"
  end

  test "connect to custom action" do
    conn = simulate_request(Router, :connect, "/connect")
    assert conn.status == 200
    assert conn.resp_body == "users connect"
  end

  test "trace to custom action" do
    conn = simulate_request(Router, :trace, "/trace")
    assert conn.status == 200
    assert conn.resp_body == "users trace"
  end

  test "head to custom action" do
    conn = simulate_request(Router, :head, "/head")
    assert conn.status == 200
    assert conn.method == "HEAD"
    assert conn.resp_body == ""
  end

  test "unmatched route returns 404" do
    conn = simulate_request(Router, :get, "route_does_not_exist")
    assert conn.status == 404
  end

  test "dispatch crash returns 500 and renders friendly error page" do
    conn = simulate_request(Router, :get, "route_that_crashes")
    assert conn.status == 500
    assert conn.resp_body =~ ~r/Something went wrong/i
    refute conn.resp_body =~ ~r/Stacktrace/i
  end

  test "splat arg with preceding named parameter to files/:user_name/*path" do
    conn = simulate_request(Router, :get, "files/elixir/Users/home/file.txt")
    assert conn.status == 200
    assert conn.params["user_name"] == "elixir"
    assert conn.params["path"] == "Users/home/file.txt"
  end

  test "splat arg with preceding string to backups/*path" do
    conn = simulate_request(Router, :get, "backups/name")
    assert conn.status == 200
    assert conn.params["path"] == "name"
  end

  test "splat arg with multiple preceding strings to static/images/icons/*path" do
    conn = simulate_request(Router, :get, "static/images/icons/elixir/logos/main.png")
    assert conn.status == 200
    assert conn.params["image"] == "elixir/logos/main.png"
  end

  test "limit resource by passing :except option" do
    conn = simulate_request(Router, :delete, "posts/2")
    assert conn.status == 404
    conn = simulate_request(Router, :get, "posts/new")
    assert conn.status == 200
  end

  test "limit resource by passing :only option" do
    conn = simulate_request(Router, :put, "sessions/2")
    assert conn.status == 404
    conn = simulate_request(Router, :get, "sessions/")
    assert conn.status == 404
    conn = simulate_request(Router, :get, "sessions/1")
    assert conn.status == 404
    conn = simulate_request(Router, :get, "sessions/new")
    assert conn.status == 200
    conn = simulate_request(Router, :post, "sessions")
    assert conn.status == 200
    conn = simulate_request(Router, :delete, "sessions/1")
    assert conn.status == 200
  end

  test "named route builds _path url helper" do
    assert Router.user_path(id: 88) == "/users/88"
  end

  test "Parsers.Fallback prevents Plug.Parsers from raising UnsupportedMediaTypeError" do
    conn = conn(:get, "users/1", nil, [headers: [{"content-type", "application/widget"}]])
    conn = Router.call(conn, [])
    assert conn.status == 200
    assert conn.params["id"] == "1"
  end

  test "catch-all splat route matches" do
    conn = simulate_request(CatchAllRouter, :get, "foo/bar/baz")
    assert conn.status == 404
    assert conn.params == %{"path" => "foo/bar/baz"}
    assert conn.resp_body == "not found"
  end
end

