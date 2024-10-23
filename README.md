# Personnal Website
#### Website made in ruby with sinatra

## Gems needed :
- sinatra-contrib
- rackup
- webrick
- mysql2
- faraday
- awesome_print
- absolute_time

## Description
This website is made to display my different projects and to be used as a tool for different projects.

## Other
This website interacts with the database used in the [Joel Bot](https://github.com/Venorrak/JoelBot) project to display the stats of the channels and

## API

### Get users  :
get list of all users

URL : https://server.venorrak.dev/api/joels/users

#### Input (query)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| way | String | Yes | ASC, DESC
| sort | String | Yes | count, creationDate, name

#### Output
| Field | type | description
|-------|------|---------------------
| name | String | name of the user
| date | Date | date of first registered Joel
| count | Integer | number of times the user has said Joel

#### Example
```
https://server.venorrak.dev/api/joels/users?sort=count&way=ASC
```
<hr>

### Get channels :
get list of all channels

URL : https://server.venorrak.dev/api/joels/channels

#### Input (query)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| way | String | Yes | ASC, DESC
| sort | String | Yes | count, creationDate, name

#### Output
| Field | type | description
|-------|------|---------------------
| name | String | name of the channel
| date | Date | date of first registered Joel
| count | Integer | number of times someone has said Joel in the channel

#### Example
```
https://server.venorrak.dev/api/joels/channels?sort=count&way=ASC
```

<hr>

### Get user info :
get info of a single user

URL : https://server.venorrak.dev/api/joels/users/twitchname

#### Input (url)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| name | String | Yes | name of a registered user

#### Output

| Field | type | description
|-------|------|---------------------
| name | String | name of the user
| date | Date | date of first registered Joel
| count | Integer | number of times the user has said Joel
| pfp | String | url of profile picture
| bgp | String | url of offline picture
| twitch_id | Integer | the twitch id of the user
| rarity | Float | the rariry of the user

#### Example
```
https://server.venorrak.dev/api/joels/users/venorrak
```

<hr>

### Get channel info :
get info of a single channel

URL : https://server.venorrak.dev/api/joels/channels/twitchname

#### Input (url)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| name | String | Yes | name of a registered channel

#### Output
| Field | type | description
|-------|------|---------------------
| name | String | name of the channel
| date | Date | date of first registered Joel
| count | Integer | number of times someone has said Joel in the channel
| rarity | Float | the rariry of the channel

#### Example
```
https://server.venorrak.dev/api/joels/channels/venorrak
```

<hr>

### Get channel history :
Get number of Joel for each stream of the selected streamer

URL : https://server.venorrak.dev/api/joels/channels/history/twitchname

#### Input (url)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| name | String | Yes | name of a registered channel

#### Input (query)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| limit | INT | NO | positive INT
By default, the limit is set to 10

#### Output
Array of :
| Field | type | description
|-------|------|---------------------
| count | Int | number of Joel for the stream
| date | Date | date of the stream

#### Example
```
https://server.venorrak.dev/api/joels/channels/history/venorrak
https://server.venorrak.dev/api/joels/channels/history/venorrak?limit=20
```

<hr>

### Get User history :
Get number of Joel for each stream of the selected user

URL : https://server.venorrak.dev/api/joels/users/history/twitchname

#### Input (url)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| name | String | Yes | name of a registered User

#### Input (query)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| limit | INT | NO | positive INT
By default, the limit is set to 10

#### Output
Array of :
| Field | type | description
|-------|------|---------------------
| count | Int | number of Joel for the stream
| date | Date | date of the stream
| channel_name | String | name of the streamer hosting the stream 

#### Example
```
https://server.venorrak.dev/api/joels/users/history/venorrak
https://server.venorrak.dev/api/joels/users/history/venorrak?limit=20
```
