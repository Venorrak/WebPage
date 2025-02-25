# Personnal Website
#### Website made in ruby with sinatra

## Index

- [Gems needed](#gems-needed-)
- [Description](#description)
- [Other](#other)
- [API](#api)
    - [Get Users](#get-users--)
    - [Get Channels](#get-channels-)
    - [Get User Data](#get-user-info-)
    - [Get Channel Data](#get-channel-info-)
    - [Get Channel History](#get-channel-history-)
    - [Get User History](#get-user-history-)
    - [Get JCP short term history](#get-jcp-short-term-history)
    - [Get JCP long term history](#get-jcp-long-term-history)
    - [Get Streams](#get-streams)
    - [Get User Stats](#get-stats-on-a-person)

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


<hr>


### Get JCP short term history
Get the JCP over the last 24 hours
JCP is updated each 15 seconds when bot is online

URL : https://server.venorrak.dev/api/joels/JCP/short

#### Input (query)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| limit | INT | NO | positive INT
| minutes | INT | NO | positive INT

"minutes" is used to get all data for the last x amount of minutes
#### Output
Array of :
| Field | type | description
|-------|------|---------------------
| JCP | DOUBLE | % of Joel Counciousness
| timestamp | DATETIME | YYYY-MM-DD HH:MM:SS timestamp of JCP

#### Example
```
https://server.venorrak.dev/api/joels/JCP/short
https://server.venorrak.dev/api/joels/JCP/short?limit=10
https://server.venorrak.dev/api/joels/JCP/short?minutes=30
```


<hr>


### Get JCP long term history
Get the JCP for all of its lifetime
JCP is updated each minute when bot is online

URL : https://server.venorrak.dev/api/joels/JCP/long

#### Input (query)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| limit | INT | NO | positive INT
| since | DATETIME | NO | YYYY-MM-DD HH:MM:SS

By default, limit is set to 10,080 or 1 week

"since" is used to get all JCP since the date specified

#### Output
Array of :
| Field | type | description
|-------|------|---------------------
| JCP | DOUBLE | % of Joel Counciousness
| timestamp | DATETIME | YYYY-MM-DD HH:MM:SS timestamp of JCP

#### example
```
https://server.venorrak.dev/api/joels/JCP/long
https://server.venorrak.dev/api/joels/JCP/long?limit=10
https://server.venorrak.dev/api/joels/JCP/long?since=2020-11-09 20:40:59
```

<hr>

### Get Streams
Get the stats for each stream tracked by Joel Bot

URL : https://server.venorrak.dev/api/joels/streams

#### Input (query)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| limit | int | no | positive int
| way | string | no | "ASC", "DESC"
| sort | string | no | "count", "Date"

##### Output
Array of :
| Field | type | description
|-------|------|---------------------
| name | string | name of the channel
| count | int | number of Joel said
| streamDate | Date | date of the stream

#### example
```
https://server.venorrak.dev/api/joels/streams
https://server.venorrak.dev/api/joels/streams?limit=5&way=ASC&sort=count
```

<hr>

### Get stats on a person
Get the Joel stats for a person

URL : https://server.venorrak.dev/api/joels/stats/:name

#### Input (url)
| Paramerter | Type | Required | Possible inputs
|----|------|-----------|---------------
| name | String | Yes | name of a registered User

#### Output
```
{
    name: string,
    joelThisYear: int,
    topStream: {
        name: string,
        count: int,
        date: date
    },
    topStreamer: {
        name: string,
        count: int
    }
}
```
#### example
```
https://server.venorrak.dev/api/joels/stats/venorrak
```