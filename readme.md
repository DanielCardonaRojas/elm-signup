# Elm Signup form with client and server side validation

Inputs can specify how they want their validations displayed (one at time or a list of all failed validations) (`Queued or Mass`)
inputs can specify which event triggers the display of validation messages `OnInputchange or OnBlur`

In this example a server can validate the submission of the form, it is expected that the server 
responds with this structure:

Failure or some server error
```json
{status: "error", message: "Some exception..."}
# OR
{status: "fail", message: "Some failed because ..."}
```

Succeeds
```json
{status: "ok", data: "Some confirmation string ..."}
```

## Usage

Import Form module define a list of inputs a post url and list of validations a associated with an inputs name.

```elm
import Form exposing (..)
-- formMainProgram : List Input -> URL -> List (InputName, Validation) -> Program Never Model Action
main = formMainProgram inputs "http://localhost:5000/signup" validations
```

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
    , name : String
    , label : String
    , placeholder : String
    , inputType : String
    , errors : List String
    , validationStyle : ValidationStyle
    , hideValidations : Bool
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
# Visit localhost:5000
# Automatic compilation of script using  entr
cd client
./develop.sh
```

# Todo:

- Use flags program in elm to pass in the configuration and window location
- Implement the Validation trigger option (OnInputChange or OnBlur)
- Support some form of validation that allows an input validation to succeed or fail depending on another input value 
- Needs to allow users to decorate the views
- What about a multistep registration? Using fieldsets ?
- Use iziToast.js or some library to show server notification just to showcase
