import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JsonD
import Json.Decode exposing (Decoder)

main = Html.program {init = init, view = view, subscriptions = subscriptions, update = update}

---------------- Auxliary Types ----------
type alias Validation = Input -> Maybe String
type alias Validator = Input -> List Validation -> List String
type alias InputName = String

--| Since the server will respond with {status: "failed|error", message:"..."} or {status:"ok", data: {}}
type alias ServerResponse a = Result String a 

type ValidationStyle 
    = Mass --^ Show all validations at a time
    | Queued  --^ Show message from first failed validation

type ValidationTrigger
    = OnInputChange
    | OnBlur

---------------- Actions -----------------
type Action 
    = NoAction
    | InputChanged Input String
    | FocusedOut Input
    | FocusedIn Input
    | ServerReplied (Result Http.Error (ServerResponse String))
    | SubmitForm

---------------- Model -----------------
singleErrorMessages = True 
type alias Model = { inputs : List Input, postUrl : String, serverResponse : ServerResponse String, programErrors : String }

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

-- | Short hand input constructors
textInput name label placeholder style = Input "" name label placeholder "text" [] style True
emailInput name label placeholder style = Input "" name label placeholder "email" [] style True
passwordInput name label style = Input "" name label "" "password" [] style True

initialModel = 
    let 
        inputs = 
            [ textInput "user_name" "Username: " "Enter your username" Mass
            , emailInput "user_mail" "Email: " "example@gmail.com" Mass
            , passwordInput "user_passwd" "Password: " Queued 
            ]
    in 
        Model inputs "/signup" (Ok "") ""
    
init: (Model, Cmd Action)
init = (initialModel, Cmd.none)
---------------- View -----------------
view : Model -> Html Action 
view model = 
    let 
        serverResponse =  
            case model.serverResponse of
                Ok v -> div [class "server-response"] [text v] 
                Err e -> div [class "server-response error"] [text e]

        submitButton = 
            if formErrors model.inputs > 0 then 
                button [class "btn btn-warning form-control disabled"] [text "submit"] 
            else 
                button [onClick SubmitForm, class "btn btn-warning form-control"][text "Submit"]
             
    in
        div [class "elm-form"] 
            <| List.map viewInput model.inputs 
            ++ [ submitButton
               , serverResponse
               , div [class "program-errors"] [text model.programErrors]
               ]

viewInput : Input -> Html Action
viewInput i =
    let 
        inputField = 
            div [] [input [onInput (InputChanged i), onBlur (FocusedOut i), onFocus (FocusedIn i)
                          , placeholder i.placeholder, value i.value, name i.name, type_ i.inputType, class "form-control"][]
                   ]
        errorList i =  
        if i.hideValidations then
            [text ""] 
        else
            if i.validationStyle == Queued then 
                [li [] (List.map text (List.take 1 i.errors))] 
            else 
                List.map (\e -> li [][text e]) i.errors
    in
        div [class "form-group"]
            [ label [for i.name] [text i.label] 
            , inputField 
            , ul [class "input-error"] <| errorList i
            ]
---------------- Update -----------------

update : Action -> Model -> (Model, Cmd Action) 
update action model =
    case action of
        NoAction -> (initialModel, Cmd.none)

        InputChanged i newValue -> 
            ({model | inputs = List.map (updateInput i newValue) model.inputs}, Cmd.none)
        
        FocusedOut i ->
            (changeFocusOnInput model i False, Cmd.none)

        FocusedIn i ->
            (changeFocusOnInput model i True, Cmd.none)
        
        SubmitForm -> 
            (model, loginCmd "http://localhost:5000/signup" model)

        ServerReplied r -> 
            case r of
                Ok v ->  ({model | serverResponse = v}, Cmd.none )
                Err error -> ({model | programErrors = toString error}, Cmd.none)

updateInput : Input -> String -> Input -> Input
updateInput changedInput newValue storedInput =
    if changedInput.name == storedInput.name then
        let
            updatedField = {changedInput | value = newValue}
        in 
            { updatedField | errors = inputValidator updatedField validations}
    else
        storedInput

changeFocusOnInput : Model -> Input -> Bool -> Model
changeFocusOnInput model input b = 
    let 
        modifiedInputs = List.map (\i -> if i.name == input.name then {i | hideValidations = b} else i) model.inputs
    in
        {model | inputs = modifiedInputs }

---------------- Subscriptions -----------------

subscriptions model =  Sub.none

--------------- Commands -----------------
serverResponseDecoder : Decoder a -> Decoder (ServerResponse a)
serverResponseDecoder d =  
    JsonD.field "status" JsonD.string
        |> JsonD.andThen 
           (\m -> case String.toLower m of
                    "ok"    -> JsonD.map Ok (JsonD.field "data" d) 
                    "success"    -> JsonD.map Ok (JsonD.field "data" d) 
                    "fail"  -> JsonD.map Err (JsonD.field "message" JsonD.string)
                    "error" -> JsonD.map Err (JsonD.field "message" JsonD.string)
                    _       -> JsonD.map Err (JsonD.succeed "Unkown error, server didnt respond with expected structure"))

loginCmd : String -> Model -> Cmd Action
loginCmd url model = 
    let 
        loginBody =
            Http.multipartBody  <| List.map (\i -> Http.stringPart i.name i.value) model.inputs
    in
        Http.send ServerReplied (Http.post url loginBody <| serverResponseDecoder JsonD.string)

---------------- Logic -----------------
validations : List (InputName, Validation)
validations = 
    [ ("user_name", withPredicate (not << String.isEmpty) "User name can't be empty" )
    , ("user_mail", withPredicate (String.contains "@") "Doesn't seem like a valid email")
    , ("user_passwd", withPredicate (minLength 6) "Passwords must be at least 6 characters long")
    , ("user_name", withPredicate (minLength 3) "User name is too short")
    , ("user_name", withPredicate (not << String.contains " ") "User name cant contain spaces")
    ]

--inputValidator : Validator
inputValidator : Input -> List (InputName, Validation) -> List String
inputValidator i validations = 
    List.filterMap (\v -> if Tuple.first v == i.name then (Tuple.second v) i else Nothing) validations

formErrors : List Input -> Int
formErrors inputs = List.foldl (\i acc -> List.length i.errors + acc) 0 inputs
---------------- Predicates -----------------
-- | Build a validations from a predicate and some message string
withPredicate : (String -> Bool) -> String -> Validation
withPredicate p errorMessage = \i -> if p i.value then Nothing else Just errorMessage

minLength : Int -> String -> Bool
minLength n s = String.length s >= n

