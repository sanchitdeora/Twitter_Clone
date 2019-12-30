defmodule Simulator do
  def start(data) do
   # Accept Number of Users and Number of Tweets as arguments
#   [num_user, num_msg] = System.argv
#   {num_user, _} = Integer.parse(num_user)
#   {num_msg, _} = Integer.parse(num_msg)



   num_user = Map.fetch!(data, "numUsers")
   num_msg = Map.fetch!(data, "numTweets")
   {num_user, _} = Integer.parse(num_user)
   {num_msg, _} = Integer.parse(num_msg)


   Process.register(self(), Main)

   # Start Twitter Engine
   {:ok, server_pid} = TwitterEngine.start_link([])
   simulation_server_pid = Application.put_env(TwitterEnginePhx, :simulationerverpid, server_pid)
   userlist = Utility.getUserCredentials(num_user)

   usernameList = Enum.map(userlist, fn user ->
     {username, password} = user
     username
   end)

   client_ids = Enum.map(0..(num_user - 1), fn userid ->
     credentials = Enum.at(userlist, userid)
     {username, password} = credentials
     Client.start_link({server_pid, userid, credentials, List.delete(usernameList, username), num_msg})
   end)

   Enum.map(client_ids, fn curr ->
     {:ok, client_id} = curr
     ret = Client.createAccount(client_id, client_id)
   end)

   Process.sleep(2000)
   spawn fn() -> getAllUsers(server_pid) end
   spawn fn() -> getLatestTweets(server_pid) end
   spawn fn() -> getAllHashtags(server_pid) end

    Enum.map(client_ids, fn curr ->
      {:ok, client_id} = curr
      #    Process.sleep(100)
       _state_after_exec = :sys.get_state(client_id, :infinity)
    end)
   #  Utility.generateRandomTweet(70, usernameList)

    {_, t1} = :erlang.statistics(:wall_clock)
    IO.puts "Time taken to complete the simulation is #{t1} milliseconds"
    Process.sleep(5000)

    TwitterEnginePhxWeb.Endpoint.broadcast!("simulator:lobby", "termination", %{"state" => true})
    Process.sleep(2000)

  end

  def getAllUsers(server_pid) do
   {response, data} = TwitterEngine.chooseProcessor(server_pid)
    if response == :proceed do
       {code, all_users} = TwitterProcessor.getListofUsers(data)
       if code == :ok do
         TwitterEnginePhxWeb.Endpoint.broadcast!("simulator:lobby", "ListOfUsers", %{"users" => all_users})
       end
    end
   Process.sleep(3000)
   getAllUsers(server_pid)
  end

  def getAllHashtags(server_pid) do
    Process.sleep(1500)
    {response, data} = TwitterEngine.chooseProcessor(server_pid)
    if response == :proceed do
      {code, all_hashtags} = TwitterProcessor.getListofHashtags(data)
      if code == :ok do
        all_hashtags = Enum.sort_by all_hashtags, &Map.fetch(&1, "count")
        all_hashtags = Enum.reverse(all_hashtags)
        TwitterEnginePhxWeb.Endpoint.broadcast!("simulator:lobby", "ListOfHashtags", %{"hashtags" => all_hashtags})
      end
    end
    getAllHashtags(server_pid)
  end

  def getLatestTweets(server_pid) do
    {response, data} = TwitterEngine.chooseProcessor(server_pid)
    if response == :proceed do
      {code, latest_tweets} = TwitterProcessor.getLatestTweets(data)
      if code == :ok do
        TwitterEnginePhxWeb.Endpoint.broadcast!("simulator:lobby", "ListOfTweets", %{"tweets" => latest_tweets})
      end
    end
    Process.sleep(500)
    getLatestTweets(server_pid)
  end

  def getUserRetweets(server_pid, username) do

    {response, data} = TwitterEngine.chooseProcessor(server_pid)
    if response == :proceed do
      {code, retweets} = TwitterProcessor.getUserRetweets(data, username)
      if code == :ok do
        retweetList = Enum.map(retweets, fn curr ->
          {_id, {uname, _date, tweet}} = curr
          value = %{"uname" => uname, "tweet" => tweet}
          value
        end)
        retweetList = Enum.slice(retweetList, 0, 10)
        TwitterEnginePhxWeb.Endpoint.broadcast!("simulator:lobby", "ListOfRetweets", %{"retweets" => retweetList})
      end
    end
  end

  def getUserMentions(server_pid, username) do

    {response, data} = TwitterEngine.chooseProcessor(server_pid)
    if response == :proceed do
      {code, mentions} = TwitterProcessor.getUserMentions(data, username)
      if code == :ok do
        mentionList = Enum.map(mentions, fn curr ->
          {_id, {uname, _date, tweet}} = curr
          value = %{"uname" => uname, "tweet" => tweet}
          value
        end)
        mentionList = Enum.slice(mentionList, 0, 10)
        TwitterEnginePhxWeb.Endpoint.broadcast!("simulator:lobby", "ListOfMentions", %{"mentions" => mentionList})
      end
    end
  end

  def getHashtagTweets(server_pid, tag) do
    {response, data} = TwitterEngine.chooseProcessor(server_pid)
    if response == :proceed do
      {code, hashtagTweets} = TwitterProcessor.getTweetsFromHashtags(data, tag)
      if code == :ok do
        hashtagTweetsList = Enum.map(hashtagTweets, fn curr ->
          {_id, {uname, _date, tweet}} = curr
          value = %{"uname" => uname, "tweet" => tweet}
          value
        end)
        hashtagTweetsList = Enum.slice(hashtagTweetsList, 0, 10)
        TwitterEnginePhxWeb.Endpoint.broadcast!("simulator:lobby", "ListOfHashtagTweets", %{"hashtagTweets" => hashtagTweetsList})
      end
    end
  end

end