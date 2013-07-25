# API description - Shownotes Message Service

## GET Resources

### Get this API description

* URI: http://example.org/rest
* Methode: GET
* Auth: BASIC

#### Returns

This documentation

### Get all subscribers with full information

* URI: http://example.org/rest/subscriber
* Methode: GET
* Auth: BASIC

#### Returns

HTTP Status: 200 OK

Content-Type: application/JSON

Data:

```
{
    "anon@example.org":{
                            "pad":"",
                            "info":"1"
                        },
    "anon2@example.org":{
                            "pad":"anon",
                            "info":"0"
                        }
}
```

or, if there is no subscriber at all

HTTP Status: 204 No Content

Content-Type: text/html

Data: -


### Get a specific subscriber by jid with full information

* URI: http://example.org/rest/subscriber
* Methode: GET
* Auth: BASIC

#### Returns

HTTP Status: 200 OK

Content-Type: application/JSON

Data:

```
{
    "anon@example.org":{
                            "pad":"",
                            "info":"1"
                        },
}
```

or, if no entry

HTTP Status: 204 No Content

Content-Type: text/html

Data: -

### Get all subscriptions ordered by jid

* URI: http://example.org/rest/subscription/jid
* Methode: GET
* Auth: BASIC

#### Returns

HTTP Status: 200 OK

Content-Type: application/JSON

Data:

```
{
    "anon@example.org":[    
                            "1337kultur",
                            "alternativlos",
                            "binaergewitter",
                            "chaosradio",
                            "einschlafen"
                        ],
    "anon2@example.org":[     
                            "aboutradio",
                            "binaergewitter",
                            "bluemoon",
                            "breitband",
                            "cre"
                        ]
}
```

or, if there is no entry

HTTP Status: 204 No Content

Content-Type: text/html

Data: -

### Get all subscriptions for a specific jid

* URI: http://example.org/rest/subscription/jid/{jid}
* Methode: GET
* Auth: BASIC

#### Returns

HTTP Status: 200 OK

Content-Type: application/JSON

Data:

```
{
    "anon@example.org":[    
                            "1337kultur",
                            "alternativlos",
                            "binaergewitter",
                            "chaosradio",
                            "einschlafen"
                        ]
}
```

or, if there is no entry

HTTP Status: 204 No Content

Content-Type: text/html

Data: -

### Get all subscribed jids ordered by slugs

* URI: http://example.org/rest/subscription/slug
* Methode: GET
* Auth: BASIC

#### Returns

HTTP Status: 200 OK

Content-Type: application/JSON

Data:

```
{
    "1337kultur":[
                    "anon2@example.org"
                 ],
    "aboutradio":[
                    "anon@example.org"
                 ],
    "alternativlos":[
                        "anon@example.org",
                        "anon2@example.org"
                    ]
}
```

or, if there is no entry

HTTP Status: 204 No Content

Content-Type: text/html

Data: -

### Get all subscribed jids from a specifc slug

#### Returns

* URI: http://example.org/rest/subscription/slug/{slug}
* Methode: GET
* Auth: BASIC

HTTP Status: 200 OK

Content-Type: application/JSON

Data:

```
{
    "einschlafen":[
                        "anon@example.org",
                        "anon2@example.org"
                  ]
}
```

or, if there is no entry

HTTP Status: 204 No Content

Content-Type: text/html

Data: -

## PUT Resources

### Subscribe a user to one ore more slugs by jid

* URI: http://example.org/rest/subscribe
* Methode: PUT
* Auth: BASIC
* Content-Type: application/json

Data:

```
{
    "einschlafen":[
                        "anon@example.org",
                        "anon2@example.org"
                  ]
}
```

### Returns

HTTP Status: 200 OK

Content-Type: text/html

Data: 

or, if there is no entry for one or more slugs

HTTP Status: ????

Content-Type: application/json

Data:

```
{
    "erroron":[
                  "foo",
                  "barz"
              ]
}
```

