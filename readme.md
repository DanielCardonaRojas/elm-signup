# Elm Signup form with client and server side validation

This is just a simple attempt at understanding how to write forms in elm.


**Core types**

```elm
type alias Validation = Input -> Maybe String
type alias Validator = Input -> List (InputName, Validation) -> List String
type alias InputName = String
```

**Initiailize the model with a list of inputs**

```elm
type alias Input = 
    { value : String
    , name : InputName
    , label : String
    , placeholder : String
    , inputType : String
    , errors : List String
    }
```

**Create a list of validations**

Assign validations to a given field referencing a field by its unique name 

```elm
validations : List (InputName, Validation)
validations = 
    [ ("user_name", withPredicate (not << String.isEmpty) "User name cant be empty" )
    , ("user_mail", withPredicate (String.contains "@") "Doesn't seem like a valid password")
    , ("user_passwd", withPredicate (minLength 6) "Passwords must be at least 6 characters long")
    , ("user_name", withPredicate (minLength 3) "User name is too short")
    , ("user_name", withPredicate (not << String.contains " ") "User name cant contain spaces")
    ]
```

# Run 

Clone and inside the folder  run

```shell
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt
python server.py
#Visit localhost:5000
```

# Todo:

- Configure to switch between single and multiple errors per input field.
- Use flags program in elm to pass in the configuration and window location
- Create helper predicates to validate
