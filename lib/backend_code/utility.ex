defmodule Utility do

  def getUserCredentials(num_user, userList \\ []) do
      if num_user > 0 do
        usernameLength = Enum.random(5..12)
        username = generateRandomCredential(usernameLength)

        passwordLength = Enum.random(8..15)
        password = generateRandomCredential(passwordLength)
        user = {username, password}
        if Enum.member?(userList, user) do
          getUserCredentials(num_user, userList)
        else
          getUserCredentials(num_user - 1, userList ++ [user])
        end
      else
        userList
      end
  end

  def generateRandomCredential(length) do
    alphabets = "abcdefghijklmnopqrstuvwxyz"
    cred = Enum.map(1..length, fn i ->
      String.at(alphabets, Enum.random(0..(String.length(alphabets) - 1)))
    end)
    cred = Enum.join(cred)
    cred
  end

  def generateRandomTweet(length, otherUsers) do
    alphabets = "abcdefghijklmnopqrstuvwxyz "
    hashtags = getHashTagList()
    tweet = ""
    temp = Enum.map(1..length, fn i ->
      String.at(alphabets, Enum.random(0..(String.length(alphabets) - 1)))
    end)
    temp = Enum.join(temp)
    mentions = addMentions(otherUsers)
    tweet = temp <> mentions
    tags = addHashtags(hashtags)
    tweet = tweet <> tags
  end

  def addMentions(otherUsers) do
    mentionCount = Enum.random(0..2)
    mentionString =
      if mentionCount > 0 do
      mentions = Enum.map(1..mentionCount, fn n ->
        other = Enum.random(otherUsers)
        " @" <> other
      end)
      mentions = Enum.join(mentions)
      mentions
    else
      ""
    end
    mentionString
  end

  def getHashTagList() do
    hashtags = ["#cool", "#fun", "#sad", "#happy", "#excited", "#twitterEngine", "#colorful", "#worried", "#foodie", "#dosProject"]
    hashtags
  end

  def addHashtags(hashtags) do
    hashtagCount = Enum.random(0..3)
    hashtagString =
      if hashtagCount > 0 do
      hashtagList = Enum.map(1..hashtagCount, fn n ->
        hashtag = Enum.random(hashtags)
        hashtag
      end)
      hashtagList = Enum.uniq(hashtagList)
      tags = Enum.join(hashtagList, " ")
      " " <> tags
    else
      ""
    end
    hashtagString
  end

end
