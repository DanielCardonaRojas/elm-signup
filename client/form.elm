module Form exposing (formMainProgram, textInput, emailInput, passwordInput, withPredicate
                     , textInputWithTrigger, emailInputWithTrigger, passwordInputWithTrigger
                     , Validation, ValidationStyle(..), ValidationTrigger(..))

import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JsonD
import Json.Decode exposing (Decoder)


formMainProgram : List Input -> URL -> List (InputName, Validation) -> Program Never Model Action
formMainProgram inputs postUrl vs = 
    Html.program {init = (initialModelWith inputs postUrl vs, Cmd.none) 
                 , view = view
                 , subscriptions = subscriptions
                 , update = update}

initialModelWith : List Input -> URL -> List (InputName, Validation) -> Model
initialModelWith inputs postUrl validations = 
        {inputs =  inputs, postUrl = postUrl, serverResponse =  (Ok ""), programErrors = "", validations = validations } 

---------------- Auxliary Types ----------
type alias Validation = Input -> Maybe String
type alias Validator = Input -> List Validation -> List String
type alias InputName = String
type alias URL = String

--| Since the server will respond with {status: "failed|error", message:"..."} or {status:"ok", data: {}}
type alias ServerResponse a = Result String a 

type ValidationStyle 
    = Mass --^ Show all validations at a time
    | Queued  --^ Show message from first failed validation

type ValidationTrigger
    = OnInputChange --^ Validate inputs as you type
    | OnBlur --^ Validate input when it looses focus

---------------- Actions -----------------
type Action 
    = NoAction
    | InputChanged Input String
    | FocusedOut Input
    | FocusedIn Input
    | ServerReplied (Result Http.Error (ServerResponse String))
    | SubmitForm

---------------- Model -----------------
type alias Model = { inputs : List Input, postUrl : String, serverResponse : ServerResponse String, programErrors : String, validations : List (InputName, Validation) }

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

-- | Short hand input constructors
textInputWithTrigger trigger name label placeholder style = Input "" name label placeholder "text" [] style trigger True
emailInputWithTrigger trigger name label placeholder style = Input "" name label placeholder "email" [] style trigger True
passwordInputWithTrigger trigger name label style = Input "" name label "" "password" [] style trigger True

textInput name label placeholder style = textInputWithTrigger OnBlur name label placeholder style
emailInput name label placeholder style = emailInputWithTrigger OnBlur name label placeholder style
passwordInput name label style = passwordInputWithTrigger OnBlur name label style

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
        NoAction -> (model, Cmd.none)

        InputChanged i newValue -> 
            let 
                updatedModel = {model | inputs = List.map (updateInput i newValue model.validations) model.inputs} 
            in
                if not <| i.validationTrigger == OnInputChange then
                    (updatedModel, Cmd.none)
                else
                    (toggleValidationsOnInput updatedModel i False, Cmd.none)
        
        FocusedOut i ->
            (toggleValidationsOnInput model i False, Cmd.none)

        FocusedIn i ->
            (toggleValidationsOnInput model i True, Cmd.none)
        
        SubmitForm -> 
            (model, loginCmd model)

        ServerReplied r -> 
            case r of
                Ok v ->  ({model | serverResponse = v}, Cmd.none )
                Err error -> ({model | programErrors = toString error}, Cmd.none)

updateInput : Input -> String -> List (InputName, Validation) -> Input -> Input
updateInput changedInput newValue validations storedInput =
    if changedInput.name == storedInput.name then
        let
            updatedField = {changedInput | value = newValue}
        in 
            { updatedField | errors = inputValidator updatedField validations}
    else
        storedInput

toggleValidationsOnInput : Model -> Input -> Bool -> Model
toggleValidationsOnInput model input b = 
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

loginCmd : Model -> Cmd Action
loginCmd model = 
    let 
        loginBody =
            Http.multipartBody  <| List.map (\i -> Http.stringPart i.name i.value) model.inputs
    in
        Http.send ServerReplied (Http.post model.postUrl loginBody <| serverResponseDecoder JsonD.string)

---------------- Logic -----------------

inputValidator : Input -> List (InputName, Validation) -> List String
inputValidator i validations = 
    List.filterMap (\v -> if Tuple.first v == i.name then (Tuple.second v) i else Nothing) validations

formErrors : List Input -> Int
formErrors inputs = List.foldl (\i acc -> List.length i.errors + acc) 0 inputs

---------------- Predicates -----------------
-- | Build a validations from a predicate and some message string
withPredicate : (String -> Bool) -> String -> Validation
withPredicate p errorMessage = \i -> if p i.value then Nothing else Just errorMessage

