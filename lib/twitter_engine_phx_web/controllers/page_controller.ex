defmodule TwitterEnginePhxWeb.PageController do
  use TwitterEnginePhxWeb, :controller

  def index(conn, _params) do
    if !is_nil(Plug.Conn.get_session(conn, "inSession")) && Plug.Conn.get_session(conn, "inSession") do
      redirect(conn, to: "/home")
    else
      render(conn, "index.html")
    end
  end

  def start(conn, params) do
    spawn fn() -> (Simulator.start(params)) end
    render(conn, "summary.html")
  end

  def login(conn, params) do
    if !is_nil(Plug.Conn.get_session(conn, "inSession")) && Plug.Conn.get_session(conn, "inSession") do
      redirect(conn, to: "/home")
    else
      render(conn, "login.html")
    end
  end

  def simulator(conn, params) do
    render(conn, "simulator.html")
  end

  def logout(conn, params) do
    conn =
      if !is_nil(Plug.Conn.get_session(conn, "inSession")) && Plug.Conn.get_session(conn, "inSession") do
        conn = Plug.Conn.delete_session(conn, :inSession)
        conn = Plug.Conn.delete_session(conn, :username)
        conn = Plug.Conn.delete_session(conn, :password)
      end
    render(conn, "index.html")
  end

  def signup(conn, params) do
    if !is_nil(Plug.Conn.get_session(conn, "inSession")) && Plug.Conn.get_session(conn, "inSession") do
      redirect(conn, to: "/home")
    else
      render(conn, "signup.html")
    end
  end

  def register_action(conn, params) do
    server_pid = Application.get_env(TwitterEnginePhx, :serverpid)
    username = Map.fetch!(params, "uname")
    password = Map.fetch!(params, "psw")
    cpassword = Map.fetch!(params, "cpsw")
    if password == cpassword do
      {response, data} = TwitterEngine.chooseProcessor(server_pid)
      if response == :proceed do
        {code, message} = TwitterProcessor.registerUser(data, {username, password})
        if code == :ok do
          render(conn, "login.html")
          else
          render(conn, "signup.html")
        end
      end
    else
      attr_list = %{:hasError => true, :reason=> "Username password did not match."}
      render(conn, "signup.html", attr_list)
    end
  end

  def login_action(conn, params) do
    if !is_nil(Plug.Conn.get_session(conn, "inSession")) && Plug.Conn.get_session(conn, "inSession") do
      redirect(conn, to: "/home")
    else
      server_pid = Application.get_env(TwitterEnginePhx, :serverpid)
      username = Map.fetch!(params, "uname")
      password = Map.fetch!(params, "psw")
      {response, data} = TwitterEngine.chooseProcessor(server_pid)
      if response == :proceed do
        {code, message} = TwitterProcessor.loginUser(data, {username, password})
        if code == :ok do
          conn = Plug.Conn.put_session(conn, :username, username)
          conn = Plug.Conn.put_session(conn, :password, password)
          conn = Plug.Conn.put_session(conn, :inSession, true)
          render(conn, "home.html")
        else
          #{inspect {code, message}}
          attr_list = %{:hasError => true, :reason=> "Invalid username/password."}
          render(conn, "login.html", attr_list)
        end
      end
    end
  end

  def home(conn, params) do
    render(conn, "home.html")
  end

  def allusers(conn, params) do
    server_pid = Application.get_env(TwitterEnginePhx, :serverpid)
    {response, data} = TwitterEngine.chooseProcessor(server_pid)
    if response == :proceed do
      {code, allUsers} = TwitterProcessor.getListofUsers(data)
      IO.inspect(allUsers)
    end
    render(conn, "allusers.html")
  end

  def posttweet(conn, params) do
    server_pid = Application.get_env(TwitterEnginePhx, :serverpid)
    tweet = Map.fetch!(params, "tweet")
    username = Plug.Conn.get_session(conn, "username")
    password = Plug.Conn.get_session(conn, "password")
    {response, data} = TwitterEngine.chooseProcessor(server_pid)
    if response == :proceed do
      {code, message} = TwitterProcessor.sendTweet(data, {username, password, tweet})
      if code == :ok do
        render(conn, "home.html")
      else
        attr_list = %{:hasError => true, :reason=> "Invalid Tweet."}
        render(conn, "home.html", attr_list)
      end
    end
    render(conn, "home.html")
  end

end