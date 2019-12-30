defmodule Client do
  use GenServer

  # CLIENT SIDE
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  def createAccount(server, args) do
    GenServer.cast(server, {:createAccount, args})
  end

  def deleteAccount(server) do
    GenServer.cast(server, {:deleteAccount})
  end

  def sendTweet(server,args) do
    GenServer.cast(server, {:sendTweet, args})
  end

  def subscribeUser(server, args) do
    GenServer.cast(server, {:subscribeUser, args})
  end

  def retweet(server, args) do
    GenServer.cast(server, {:retweet, args})
  end

  def getTweetsFromHashtags(server, tweet) do
    GenServer.cast(server, {:getTweetsFromHashtags, tweet})
  end

  def getMyMentions(server) do
    GenServer.cast(server, {:getMyMentions})
  end

  def getMyRetweets(server) do
    GenServer.cast(server, {:getMyRetweets})
  end

  def getMySubscribedTweets(server) do
    GenServer.cast(server, {:getMySubscribedTweets})
  end

  def done(server) do
    GenServer.cast(server, {:done})
  end


  def randomDecisionMaker(state, pid, tweetCount) do
    tweetFactor = 0.4
    limit = (tweetCount * tweetFactor) |> :erlang.trunc()
    # Tweet
    length = Enum.random(20..30)
    otherUsers = Map.fetch!(state, :otherUsers)
    limit =
      if limit < 1 do
        1
      else
        limit
    end
    Enum.map(1..limit, fn count ->
      tweet = Utility.generateRandomTweet(length, otherUsers)
      Client.sendTweet(pid, tweet)
    end)
    tweetCount = tweetCount - limit

    d = Enum.random(0..100)
    cond do
      d < 30 ->
        # Subscribe User
        otherUsers = Map.fetch!(state, :otherUsers)
        subUser = Enum.random(otherUsers)
        Client.subscribeUser(pid, subUser)
#        Process.sleep(3000)
#        Client.getMySubscribedTweets(pid)

      d < 45 ->
        # Get Tweets From a particular Hashtag
        hashtags = Utility.getHashTagList()
        tag = Enum.random(hashtags)
#        Process.sleep(3000)
#        Client.getTweetsFromHashtags(pid, tag)
        {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
        username = Map.fetch!(state, :username)
        userid = Map.fetch!(state, :userId)
        {code, tweets} = TwitterProcessor.getTweetsFromHashtags(proccessor_id, tag)
        #IO.inspect(tweets, label: "[User#{userid}] #{username} searched for tweets with #{tag}: ")
        if tweets != [] do
          retweet = Enum.random(tweets)
          Client.retweet(pid, retweet)
        end

#        Client.getMySubscribedTweets(pid)

      d < 60 ->
         # Get Tweets From My Subscribed Users
#        Process.sleep(3000)
#        Client.getMySubscribedTweets(pid)
        {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
        username = Map.fetch!(state, :username)
        password = Map.fetch!(state, :password)
        userid = Map.fetch!(state, :userId)
        {code, tweets} = TwitterProcessor.getSubscribedTweets(proccessor_id, {username, password})
        #IO.inspect(tweets, label: "[User#{userid}] #{username} searched for tweets from the other users subscribed: ")
        if tweets != [] do
          retweet = Enum.random(tweets)
          Client.retweet(pid, retweet)
        end

      d < 70 ->
        # Get Tweets where I am mentioned
#        Process.sleep(100)
#        Client.getMyMentions(pid)
        {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
        username = Map.fetch!(state, :username)
        password = Map.fetch!(state, :password)
        userid = Map.fetch!(state, :userId)
        {code, tweets} = TwitterProcessor.getMyMentions(proccessor_id, {username, password})
        #IO.inspect(tweets, label: "[User#{userid}] #{username} searched for tweets with his mentions: ")
        if tweets != [] do
          retweet = Enum.random(tweets)
          Client.retweet(pid, retweet)
        end

      d < 80 ->
#        # Get My Retweets
#        Process.sleep(3000)
        Client.getMyRetweets(pid)
#
      d < 90 ->
        # Stop the Client
        Client.done(pid)
      true ->
        # Delete Account
#        Process.sleep(1000)
        Client.deleteAccount(pid)
    end
    ifDone = Map.fetch!(state, :ifDone)
    if tweetCount > 0 &&  ifDone == false do
#      Process.sleep(1000)
      randomDecisionMaker(state, pid, tweetCount)
    end
  end


  # SERVER SIDE
  def init(args) do
    {server_pid, userid, {username, password}, otherUsers, num_msg} = args
    state = %{
              :server_pid => server_pid, :userId => userid, :username => username, :password => password,
              :otherUsers => otherUsers, :tweetCount => num_msg, :ifDone => false
              }
    {:ok, state}
    end

  def handle_cast({:createAccount, args}, state) do
    mypid = args
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    password = Map.fetch!(state, :password)
    userid = Map.fetch!(state, :userId)
    {code, message} = TwitterProcessor.registerUser(proccessor_id, {username, password})
#    IO.puts("[User#{userid}] #{username} has joined Twitter!!")
    tweetCount = Map.fetch!(state, :tweetCount)
    randomDecisionMaker(state, mypid, tweetCount)
    {:noreply, state}
  end

  def handle_cast({:deleteAccount}, state) do
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    password = Map.fetch!(state, :password)
    userid = Map.fetch!(state, :userId)
    {code, message} = TwitterProcessor.deleteUser(proccessor_id, {username, password})
#    IO.puts("[User#{userid}] #{username} just left Twitter. :( ")
    {:noreply, state}
  end

  def handle_cast({:sendTweet, args}, state) do
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    password = Map.fetch!(state, :password)
    userid = Map.fetch!(state, :userId)

    {code, message} = TwitterProcessor.sendTweet(proccessor_id, {username, password, args})
    #IO.inspect({code, message}, label: "[User#{userid}] #{username} posted #{args}: ")
    {:noreply, state}
  end

  def handle_cast({:subscribeUser, subUser}, state) do
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    password = Map.fetch!(state, :password)
    userid = Map.fetch!(state, :userId)
    {code, message} = TwitterProcessor.subscribeUser(proccessor_id, {username, password, subUser})
    #IO.inspect({code, message}, label: "[User#{userid}] #{username} subscribed to #{subUser}: ")
    {:noreply, state}
  end

  def handle_cast({:retweet, args}, state) do
    {tweetid, {_, _, tweet}} = args
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    password = Map.fetch!(state, :password)
    userid = Map.fetch!(state, :userId)
    {code, message} = TwitterProcessor.retweet(proccessor_id, {username, password, tweetid})
    #IO.inspect({code, message}, label: "[User#{userid}] #{username} retweeted '#{tweet}:' ")
    {:noreply, state}
  end

  def handle_cast({:getTweetsFromHashtags, tag}, state) do
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    userid = Map.fetch!(state, :userId)
    {code, tweets} = TwitterProcessor.getTweetsFromHashtags(proccessor_id, tag)
    #IO.inspect({code, tweets}, label: "[User#{userid}] #{username} searched for tweets with #{tag}: ")
    {:noreply, state}
  end

  def handle_cast({:getMyMentions}, state) do
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    password = Map.fetch!(state, :password)
    userid = Map.fetch!(state, :userId)
    {code, tweets} = TwitterProcessor.getMyMentions(proccessor_id, {username, password})
    #IO.inspect({code, tweets}, label: "[User#{userid}] #{username} searched for tweets with his mentions: ")
    {:noreply, state}
  end

  def handle_cast({:getMyRetweets}, state) do
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    password = Map.fetch!(state, :password)
    userid = Map.fetch!(state, :userId)
    {code, message} = TwitterProcessor.getMyRetweets(proccessor_id, {username, password})
    {:noreply, state}
  end

  def handle_cast({:getMySubscribedTweets}, state) do
    {response, proccessor_id} = TwitterEngine.chooseProcessor(Map.fetch!(state, :server_pid))
    username = Map.fetch!(state, :username)
    password = Map.fetch!(state, :password)
    userid = Map.fetch!(state, :userId)
    {code, tweets} = TwitterProcessor.getSubscribedTweets(proccessor_id, {username, password})
    #IO.inspect({code, tweets}, label: "[User#{userid}] #{username} searched for tweets from the other users subscribed: ")
    {:noreply, state}
  end

  def handle_cast({:done}, state) do
    state = Map.replace!(state, :ifDone, true)
    username = Map.fetch!(state, :username)
    userid = Map.fetch!(state, :userId)
#    IO.puts("[User#{userid}] #{username} is done for the day!")
    {:noreply, state}
  end

end

