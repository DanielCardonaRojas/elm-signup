module Form exposing (formMainProgram, withPredicate)

import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JsonD
import Json.Decode exposing (Decoder)

import Form.Types exposing (..)
import Form.Input exposing(..)


formMainProgram : List Input -> URL -> List (InputName, Validation) -> Program Never Model Action
formMainProgram inputs postUrl vs = 
    Html.program {init = (initialModelWith inputs postUrl vs, Cmd.none) 
                 , view = view
                 , subscriptions = subscriptions
                 , update = update}

initialModelWith : List Input -> URL -> List (InputName, Validation) -> Model
initialModelWith inputs postUrl validations = 
        {inputs =  inputs, postUrl = postUrl, serverResponse =  (Ok ""), programErrors = "", validations = validations } 


---------------- Model -----------------
type alias Model = 
    { inputs : List Input
    , postUrl : String
    , serverResponse : ServerResponse String
    , programErrors : String
    , validations : List (InputName, Validation) }


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
            <| List.map (Html.map FieldAction << viewInput) model.inputs 
            ++ [ submitButton
               , serverResponse
               , div [class "program-errors"] [text model.programErrors]
               ]

---------------- Update -----------------

update : Action -> Model -> (Model, Cmd Action) 
update action model =
    case action of
        NoAction -> (model, Cmd.none)

        FieldAction act ->
            case act of
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


toggleValidationsOnInput : Model -> Input -> Bool -> Model
toggleValidationsOnInput model input b = 
    let 
        modifiedInputs = List.map (\i -> toggleInputValidationsOn (\name -> name == input.name) b i) model.inputs
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

formErrors : List Input -> Int
formErrors inputs = List.foldl (\i acc -> List.length i.errors + acc) 0 inputs

---------------- Predicates -----------------
-- | Build a validations from a predicate and some message string
withPredicate : (String -> Bool) -> String -> Validation
withPredicate p errorMessage = \i -> if p i.value then Nothing else Just errorMessage

