defmodule DatabaseServer do
  use GenServer

  # CLIENT SIDE
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def createUser(server, args) do
    GenServer.call(server, {:createUser, args})
  end

  def deleteUser(server, args) do
    GenServer.call(server, {:deleteUser, args})
  end

  def updateUser(server, args) do
    GenServer.call(server, {:updateUser, args})
  end

  def getUser(server, args) do
    GenServer.call(server, {:getUser, args})
  end

  def getListofUsers(server) do
    GenServer.call(server, {:getListofUsers})
  end

  def getLatestTweets(server) do
    GenServer.call(server, {:getLatestTweets})
  end

  def tweet(server, args) do
    GenServer.call(server, {:tweet, args})
  end

  def getTweet(server, args) do
    GenServer.call(server, {:getTweet, args})
  end

  def putHashtag(server, args) do
    GenServer.call(server, {:putHashtag, args})
  end

  def getHashtag(server, args) do
    GenServer.call(server, {:getHashtag, args})
  end

  def getListofHashtags(server) do
    GenServer.call(server, {:getListofHashtags})
  end

  # SERVER SIDE
  def init(var) do
    userTable = :ets.new(:userTable, [:set, :protected])
    tweetTable = :ets.new(:tweetTable, [:set, :protected])
    hashtagTable = :ets.new(:hashtagTable, [:set, :protected])
    state = %{:userTable => userTable, :tweetTable => tweetTable, :hashtagTable => hashtagTable, :tweetCountID => 0}
    {:ok, state}
  end

  def handle_call({:createUser, userData}, _from, state) do
    ifSuccessful = :ets.insert_new(Map.fetch!(state, :userTable), {Map.fetch!(userData, :username), userData})
    if ifSuccessful do
      {:reply, {:ok, "Successful"}, state}
    else
      {:reply, {:bad, "Username already in use"}, state}
    end
  end

  def handle_call({:deleteUser, username}, _from, state) do
    data = :ets.lookup(Map.fetch!(state, :userTable), username)
    if Enum.count(data) > 0 do
      :ets.delete(Map.fetch!(state, :userTable), username)
      {:reply, {:ok, "Successful"}, state}
    else
      {:reply, {:bad, "Invalid Username"}, state}
    end
  end

  def handle_call({:getListofUsers}, _from, state) do
    allUser = []
    userTable = Map.fetch!(state, :userTable)
    value = :ets.first(userTable)
    allUser = iterateUsers(userTable, value, [value])
    {:reply, {:ok, allUser}, state}
  end

  def iterateUsers(userTable, next, userlist) do
    value = :ets.next(userTable, next)
    if value == :"$end_of_table" do
      userlist
    else
      userlist = userlist ++ [value]
      iterateUsers(userTable, value, userlist)
    end
  end

  def handle_call({:getUser, username}, _from, state) do
    userList = :ets.lookup(Map.fetch!(state, :userTable), username)
    if Enum.count(userList) > 0 do
      {_id, user} = Enum.at(userList, 0)
      {:reply, {:ok, user}, state}
    else
      {:reply, {:bad, "Invalid Username"}, state}
    end
  end

  def handle_call({:updateUser, user}, _from, state) do
    userList = :ets.lookup(Map.fetch!(state, :userTable), Map.fetch!(user, :username))
    if Enum.count(userList) > 0 do
      :ets.insert(Map.fetch!(state, :userTable), {Map.fetch!(user, :username), user})
      {:reply, {:ok, "Successful"}, state}
    else
      {:reply, {:bad, "Invalid Username"}, state}
    end
  end

  def handle_call({:getTweet, tweetId}, _from, state) do
    [{tweetId, tweet}] = :ets.lookup(Map.fetch!(state, :tweetTable), tweetId)
    {:reply, {:ok, tweet}, state}
  end

  def handle_call({:getLatestTweets}, _from, state) do
    tweetTable = Map.fetch!(state, :tweetTable)
    tweetId = Map.fetch!(state, :tweetCountID)
    latest_tweets =
      if tweetId > 0 do
      tweetInfo = :ets.lookup(tweetTable, tweetId - 1)
      [{id, {uname, date, last}}] = tweetInfo
      count =
        if tweetId > 10 do
          10
        else
          tweetId
        end
       value = %{"uname" => uname, "tweet" => last }
      iterateTweets(tweetTable, tweetId - 1, [value], count - 1)
    else
      %{}
    end
    {:reply, {:ok, latest_tweets}, state}
  end

  def iterateTweets(tweetTable, tweetId, tweetMap, counter) do
    if counter == 0 do
      tweetMap
    else
      tweetInfo = :ets.lookup(tweetTable, tweetId - 1)
      [{id, {uname, date, tweet}}] = tweetInfo
      value = %{"uname" => uname, "tweet" => tweet }
      tweetMap = tweetMap ++ [value]
      iterateTweets(tweetTable, tweetId - 1, tweetMap, counter - 1)
    end
  end

  def handle_call({:tweet, tweet}, _from, state) do
    tweetId = Map.fetch!(state, :tweetCountID)
    state = Map.replace!(state, :tweetCountID, tweetId + 1)
    :ets.insert_new(Map.fetch!(state, :tweetTable), {tweetId, tweet})
    {:reply, {:ok, tweetId}, state}
  end

  def handle_call({:putHashtag, args}, _from, state) do
    {hash, tweetId} = args
    hashtagList = :ets.lookup(Map.fetch!(state, :hashtagTable), hash)
    tweetList =
    if Enum.count(hashtagList) > 0 do
      {hash, tweetList} = Enum.at(hashtagList, 0)
      tweetList = tweetList ++ [tweetId]
    else
      [tweetId]
    end
    :ets.insert(Map.fetch!(state, :hashtagTable), {hash, tweetList})
    {:reply, {:ok, "Successful"}, state}
  end
  
  def handle_call({:getHashtag, hashtag}, _from, state) do
    hashtagList = :ets.lookup(Map.fetch!(state, :hashtagTable), hashtag)
    if Enum.count(hashtagList) > 0 do
      {hash, tweetList} = Enum.at(hashtagList, 0)
      {:reply, {:ok, tweetList}, state}
    else
      {:reply, {:ok, []}, state}
    end
  end

  def handle_call({:getListofHashtags}, _from, state) do
    allHashtags = []
    t_list = []
    hashtagTable = Map.fetch!(state, :hashtagTable)
    hashtag = :ets.first(hashtagTable)
    allHashtags = if hashtag != :"$end_of_table" do
      hashtagInfo = :ets.lookup(hashtagTable, hashtag)
      [{_, t_list}] = hashtagInfo
      count = length(t_list)
      valueMap = %{"hashtag" => hashtag, "tweet_list" => t_list, "count" => count}
      iterateHashtags(hashtagTable, hashtag, [valueMap])
    else
      []
    end
    {:reply, {:ok, allHashtags}, state}
  end

  def iterateHashtags(hashtagTable, next, hashtaglist) do
    hashtag = :ets.next(hashtagTable, next)
    if hashtag == :"$end_of_table" do
      hashtaglist
    else
      hashtagInfo = :ets.lookup(hashtagTable, hashtag)
      [{_, t_list}] = hashtagInfo
      count = length(t_list)
      valueMap = %{"hashtag" => hashtag, "tweet_list" => t_list, "count" => count}
      hashtaglist = hashtaglist ++ [valueMap]
      iterateHashtags(hashtagTable, hashtag, hashtaglist)
    end
  end

end