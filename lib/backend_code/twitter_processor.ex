defmodule TwitterProcessor do
  use GenServer

  # CLIENT SIDE
  ## BACKEND SIMULATOR
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def registerUser(server, args) do
    GenServer.call(server, {:registerUser, args})
  end

  def loginUser(server, args) do
    GenServer.call(server, {:loginUser, args})
  end

  def deleteUser(server, args) do
    GenServer.call(server, {:deleteUser, args})
  end

  def subscribeUser(server, args) do
    GenServer.call(server, {:subscribeUser, args})
  end

  def sendTweet(server,args) do
    GenServer.call(server, {:sendTweet, args})
  end

  def getLatestTweets(server) do
    GenServer.call(server, {:getLatestTweets})
  end

  def getTweetsFromHashtags(server, args) do
    GenServer.call(server, {:getTweetsFromHashtags, args})
  end

  def getMyMentions(server, args) do
    GenServer.call(server, {:getMyMentions, args})
  end

  def retweet(server, args) do
    GenServer.call(server, {:retweet, args})
  end

  def getMyRetweets(server, args) do
    GenServer.call(server, {:getMyRetweets, args})
  end

  def getSubscribedTweets(server, args) do
    GenServer.call(server, {:getSubscribedTweets, args})
  end

  ## FRONTEND SIMULATOR
  def getLatestTweets(server) do
    GenServer.call(server, {:getLatestTweets})
  end

  def getListofHashtags(server) do
    GenServer.call(server, {:getListofHashtags})
  end

  def getListofUsers(server) do
    GenServer.call(server, {:getListofUsers})
  end

  def getUserRetweets(server, args) do
    GenServer.call(server, {:getUserRetweets, args})
  end

  def getUserMentions(server, args) do
    GenServer.call(server, {:getUserMentions, args})
  end

  # SERVER SIDE
  def init(database_id) do
    state = database_id
    {:ok, state}
  end

  def handle_call({:registerUser, args}, _from, state) do
    {username, password} = args
    username = String.downcase(username) |> String.trim()
    {code, message} = ifCredentialsNonEmpty(username, password)

    if code == :ok do
      newUser = %{:username => username, :password => password, :tweets => [], :following => [], :mentions => [], :retweets => [], :ifDeleted => false}
      {code, message} = DatabaseServer.createUser(state, newUser)
      {:reply, {code, message}, state}
    else
      {:reply, {code, message}, state}
    end
  end

  def handle_call({:loginUser, args}, _from, state) do
    {username, password} = args
    username = String.trim(username) |> String.downcase()
    {code, message} = credentialCheck(username, password, state)
    cond do
      code == :bad ->

        {:reply, {code, message}, state}
      true ->
        {result, user} = DatabaseServer.getUser(state, username)

        {:reply, {result, user}, state}
    end
  end

  def handle_call({:deleteUser, args}, _from, state) do
    {username, password} = args
    username = String.trim(username) |> String.downcase()

    {code, message} = credentialCheck(username, password, state)
    cond do
      code == :bad ->
        {:reply, {code, message}, state}
      true ->
        {result, user} = DatabaseServer.getUser(state, username)
        updatedInfo = Map.replace!(user, :ifDeleted, true)
        {code, message} = DatabaseServer.updateUser(state, updatedInfo)
        {:reply, {code, message}, state}
    end
  end

  def handle_call({:sendTweet, args}, _from, state) do
    {username, password, tweet} = args
    username = String.trim(username) |> String.downcase()
    tweet = String.trim(tweet)
    mentionsRegex = ~r/\@\w+/
    hashtagRegex = ~r/\#\w+/
    {code1, message1} = credentialCheck(username, password, state)
    {code2, message2} = ifStringNonEmpty(tweet, "Tweets")
    cond do
      code1 == :bad -> {:reply, {code1, message1} , state}
      code2 == :bad -> {:reply, {code2, message2} , state}
      true ->

        {result, user} = DatabaseServer.getUser(state, username)
        {:ok, tweet_id} = DatabaseServer.tweet(state, {username, DateTime.utc_now(), tweet})

        mentionsList = List.flatten(Regex.scan(mentionsRegex,tweet))
        hashtagList = List.flatten(Regex.scan(hashtagRegex,tweet))
        Enum.each(hashtagList, fn hashtag ->
          DatabaseServer.putHashtag(state, {hashtag, tweet_id})
        end)

        Enum.each(mentionsList, fn mention ->
          mentionedUsername = String.slice(mention, 1..-1)
          {code, mentionedUser} = DatabaseServer.getUser(state, mentionedUsername)
          if code == :ok && Map.fetch!(mentionedUser, :ifDeleted) == false do
            myMentions = Map.fetch!(mentionedUser, :mentions)
            updatedMentionedUser = Map.replace!(mentionedUser, :mentions, myMentions ++ [tweet_id])
            DatabaseServer.updateUser(state, updatedMentionedUser)
          end
        end)

        tweets = Map.fetch!(user, :tweets)
        updatedInfo = Map.replace!(user, :tweets, tweets ++ [tweet_id])

        {code, message} = DatabaseServer.updateUser(state, updatedInfo)
        {:reply, {code, message} , state}
    end
  end

  def handle_call({:subscribeUser, args}, _from, state) do
    {myUsername, myPassword, usernameToSubscribe} = args
    myUsername = String.trim(myUsername) |> String.downcase()
    usernameToSubscribe = String.trim(usernameToSubscribe) |> String.downcase()
    {myResult, myUser} = DatabaseServer.getUser(state, myUsername)
    {result2, userToSubscribe} = DatabaseServer.getUser(state, usernameToSubscribe)

    {code1, message1} = credentialCheck(myUsername, myPassword, state)
    {code2, message2} = credentialCheck(usernameToSubscribe, state)
    cond do
      code1 == :bad ->
        {:reply, {code1, message1}, state}

      code2 == :bad ->
        {:reply, {code2, message2}, state}

      true ->
          following = Map.fetch!(myUser, :following)
          if Enum.member?(following, usernameToSubscribe) do
            {:reply, {:bad, "Already Subscribed to user"}, state}
          else
            updatedInfo = Map.replace!(myUser, :following, following ++ [usernameToSubscribe])
            {code, message} = DatabaseServer.updateUser(state, updatedInfo)
            {:reply, {code, message}, state}
          end
    end
  end


  def handle_call({:getSubscribedTweets, args}, _from, state) do
    {username, password} = args
    username = String.trim(username) |> String.downcase()
    {code, message} = credentialCheck(username, password, state)
    cond do
      code == :bad ->
        {:reply, {code, message}, state}
      true ->
        {result, user} = DatabaseServer.getUser(state, username)
        following = Map.fetch!(user, :following)
        subscribedTweets = Enum.map(following, fn subscribedUsername ->
          {result2, subscribedUser} = DatabaseServer.getUser(state, subscribedUsername)
          tweets =
            if Map.fetch!(subscribedUser, :ifDeleted) == false do
              tweet_ids = Map.fetch!(subscribedUser, :tweets)
              tweets = Enum.map(tweet_ids, fn curr_tid ->
                {code, tweet} = DatabaseServer.getTweet(state, curr_tid)
                {curr_tid, tweet}
              end)
              tweets
            else
              []
            end
        end)
        subscribedTweets = subscribedTweets |> List.flatten()|> Enum.sort_by(&(elem(&1, 0)))
        subscribedTweets = Enum.reverse(subscribedTweets)
        {:reply, {:ok, subscribedTweets}, state}
    end
  end

  def handle_call({:getTweetsFromHashtags, tag}, _from, state) do
    {code, message} = ifStringNonEmpty(tag, "Hashtag")
    cond do
      code == :bad ->
        {:reply, {code, message}, state}
      String.at(tag, 0) != "#" -> {:reply, {:bad, "Hashtag must begin with hash."}, state}
      true ->
        {code, tweetIDList} = DatabaseServer.getHashtag(state, tag)
        tweets = Enum.map(tweetIDList, fn curr_tid ->
          {code, tweet} = DatabaseServer.getTweet(state, curr_tid)
          {curr_tid, tweet}
        end)
        tweets = tweets |> List.flatten()|> Enum.sort_by(&(elem(&1, 0)))
        tweets = Enum.reverse(tweets)
        {:reply, {:ok, tweets}, state}
    end
  end

  def handle_call({:getMyMentions, args}, _from, state) do
    {username, password} = args
    username = String.trim(username) |> String.downcase()
    {code, message} = credentialCheck(username, password, state)
    cond do
      code == :bad ->
        {:reply, {code, message}, state}
      true ->
        {result, user} = DatabaseServer.getUser(state, username)
        mentionIDs = Map.fetch!(user, :mentions)
        mentions = Enum.map(mentionIDs, fn curr_tid ->
          {code, tweet} = DatabaseServer.getTweet(state, curr_tid)
          {curr_tid, tweet}
        end)
        mentions = mentions |> List.flatten()|> Enum.sort_by(&(elem(&1, 0)))
        mentions = Enum.reverse(mentions)
        {:reply, {:ok, mentions}, state}
    end
  end

  def handle_call({:retweet, args}, _from, state) do
    {username, password, tweet_id} = args
    username = String.trim(username) |> String.downcase()
    {code, message} = credentialCheck(username, password, state)
    cond do
      code == :bad ->
        {:reply, {code, message}, state}
      true ->
        {result, user} = DatabaseServer.getUser(state, username)
        retweets = Map.fetch!(user, :retweets)
        retweets = retweets ++ [tweet_id]
        updatedInfo = Map.replace!(user, :retweets, Enum.uniq(retweets))
        {code, message} = DatabaseServer.updateUser(state, updatedInfo)
        {:reply, {code, message} , state}
      end
  end

  def handle_call({:getMyRetweets, args}, _from, state) do
    {username, password} = args
    username = String.trim(username) |> String.downcase()
    {code, message} = credentialCheck(username, password, state)
    cond do
      code == :bad ->
        {:reply, {code, message}, state}
      true ->
        {result, user} = DatabaseServer.getUser(state, username)
        retweetIDs = Map.fetch!(user, :retweets)
        retweets = Enum.map(retweetIDs, fn curr_tid ->
          {code, tweet} = DatabaseServer.getTweet(state, curr_tid)
          {curr_tid, tweet}
        end)
        retweets = retweets |> List.flatten()|> Enum.sort_by(&(elem(&1, 0)))
        retweets = Enum.reverse(retweets)
        {:reply, {:ok, retweets}, state}
    end
  end

  # FRONT END FUNCTIONS

  def handle_call({:getListofUsers}, _from, state) do
    {code, all_users} = DatabaseServer.getListofUsers(state)
    {:reply, {:ok, all_users}, state}
  end

  def handle_call({:getLatestTweets}, _from, state) do
    {code, latest_tweets} = DatabaseServer.getLatestTweets(state)
    {:reply, {:ok, latest_tweets}, state}
  end

  def handle_call({:getListofHashtags}, _from, state) do
    {code, all_hashtags} = DatabaseServer.getListofHashtags(state)
    {:reply, {:ok, all_hashtags}, state}
  end

  def handle_call({:getUserRetweets, username}, _from, state) do
    {result, user} = DatabaseServer.getUser(state, username)
    retweetIDs = Map.fetch!(user, :retweets)
    retweets = Enum.map(retweetIDs, fn curr_tid ->
      {code, tweet} = DatabaseServer.getTweet(state, curr_tid)
      {curr_tid, tweet}
    end)
    retweets = retweets |> List.flatten()|> Enum.sort_by(&(elem(&1, 0)))
    retweets = Enum.reverse(retweets)
    {:reply, {:ok, retweets}, state}
  end

  def handle_call({:getUserMentions, username}, _from, state) do
    {result, user} = DatabaseServer.getUser(state, username)
    mentionsIDs = Map.fetch!(user, :mentions)
    mentions = Enum.map(mentionsIDs, fn curr_tid ->
      {code, tweet} = DatabaseServer.getTweet(state, curr_tid)
      {curr_tid, tweet}
    end)
    mentions = mentions |> List.flatten()|> Enum.sort_by(&(elem(&1, 0)))
    mentions = Enum.reverse(mentions)
    {:reply, {:ok, mentions}, state}
  end

















  # HELPER
  defp validateUser(name, password, userObject) do
    if (name == Map.fetch!(userObject, :username) && password == Map.fetch!(userObject, :password)) do
      true
    else
      false
    end
  end

  defp ifStringNonEmpty(data, label) do
    if String.length(String.trim(data)) > 0 do
      {:ok, "Successful"}
    else
      {:bad, label <> " cannot be empty"}
    end
  end

  defp ifCredentialsNonEmpty(name, password) do
    {code, message} = ifStringNonEmpty(name, "Username")
    if code == :ok do
      ifStringNonEmpty(password, "Password")
    else
      {code, message}
    end
  end

  defp credentialCheck(username, state) do
    #    Check if username and password is not an empty string
    {code1, message1} = ifStringNonEmpty(username, "Subscribing username")
    #    Check if user exists or not
    {code2, user} = DatabaseServer.getUser(state, username)
    {code, message} = cond do
      code1 == :bad ->
        {code1, message1}
      (code2 == :bad || Map.fetch!(user, :ifDeleted) == true) ->
        {:bad, "User you are trying to subscribe does not exist"}
      true -> {:ok, "Valid"}
    end
    {code, message}
  end

  defp credentialCheck(username, password, state) do
#    Check if username and password is not an empty string
    {code1, message1} = ifCredentialsNonEmpty(username, password)
#    Check if user exists or not
    {code2, user} = DatabaseServer.getUser(state, username)
    {code, message} = cond do
      code1 == :bad ->
        {code1, message1}
      code2 == :bad || Map.fetch!(user, :ifDeleted) == true ->
        {code2, "Invalid Username"}
#     Check if username and password is correct
      validateUser(username, password, user) == false ->
        {:bad, "Invalid Username or password"}
      true -> {:ok, "Valid"}
    end
    {code, message}
  end

end