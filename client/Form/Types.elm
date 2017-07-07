module Form.Types exposing (..)
import Http

type alias Input = 
    { value : String
    , name : String
    , label : String
    , placeholder : String
    , inputType : String
    , errors : List String
    , validationStyle : ValidationStyle
    , validationTrigger : ValidationTrigger
    , hideValidations : Bool
    }
---------------- Actions -----------------
type Action 
    = NoAction
    | FieldAction InputAction
    | ServerReplied (Result Http.Error (ServerResponse String))
    | SubmitForm

type InputAction
    = FocusedOut Input
    | FocusedIn Input
    | InputChanged Input String

---------------- Auxliary Types ----------

type alias InputName = String
type alias URL = String

type alias Validation = Input -> Maybe String
type alias Validator = Input -> List Validation -> List String
--| Since the server will respond with {status: "failed|error", message:"..."} or {status:"ok", data: {}}
type alias ServerResponse a = Result String a 

type ValidationStyle 
    = Mass --^ Show all validations at a time
    | Queued  --^ Show message from first failed validation

type ValidationTrigger
    = OnInputChange --^ Validate inputs as you type
    | OnBlur --^ Validate input when it looses focus

