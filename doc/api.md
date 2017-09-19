FORMAT: 1A
HOST: https://backoffice.juliedesk.net/api/v1

# Backoffice API

# Group messages_threads

## Add syncing tag [/messages_threads/add_syncing_tag]
### Add syncing tag [POST]
Add syncing tag on an account threads (in inbox)


+ Request basic (application/json)

    + Body

            {
                "account_email": "bob@juliedesk.com"
            }

    + Schema

            {
                 "type": "object",
                 "properties": {
                    "account_email": {
                        "type": "string",
                        "format": "email"
                    }
                 },
                 "required": ["account_email"]
            }

+ Response 200 (application/json)

    + Body

             {
                "nb_updated_theads": 4
             }


+ Response 417 (application/json)

    + Body

             {
                "error_code": "INVALID_PARAMS",
                "message": "the supplied params are invalid",
                "details": []
             }


## Remove syncing tag [/messages_threads/remove_syncing_tag]
### Remove syncing tag [POST]
Remove syncing tag from an account threads (in inbox)


+ Request basic (application/json)

    + Body

            {
                "account_email": "bob@juliedesk.com"
            }

    + Schema

            {
                 "type": "object",
                 "properties": {
                    "account_email": {
                        "type": "string",
                        "format": "email"
                    }
                 },
                 "required": ["account_email"]
            }

+ Response 200 (application/json)

    + Body

             {
                "nb_updated_theads": 4
             }


+ Response 417 (application/json)

    + Body

             {
                "error_code": "INVALID_PARAMS",
                "message": "the supplied params are invalid",
                "details": []
             }