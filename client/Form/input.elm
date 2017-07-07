module Form.Input exposing(..)
import Form.Types exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)

-- | Short hand input constructors
textInputWithTrigger trigger name label placeholder style = Input "" name label placeholder "text" [] style trigger True
emailInputWithTrigger trigger name label placeholder style = Input "" name label placeholder "email" [] style trigger True
passwordInputWithTrigger trigger name label style = Input "" name label "" "password" [] style trigger True

textInput name label placeholder style = textInputWithTrigger OnBlur name label placeholder style
emailInput name label placeholder style = emailInputWithTrigger OnBlur name label placeholder style
passwordInput name label style = passwordInputWithTrigger OnBlur name label style

viewInput : Input -> Html InputAction
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

updateInput : Input -> String -> List (InputName, Validation) -> Input -> Input
updateInput changedInput newValue validations storedInput =
    if changedInput.name == storedInput.name then
        let
            updatedField = {changedInput | value = newValue}
        in 
            { updatedField | errors = inputValidator updatedField validations}
    else
        storedInput

inputValidator : Input -> List (InputName, Validation) -> List String
inputValidator i validations = 
    List.filterMap (\v -> if Tuple.first v == i.name then (Tuple.second v) i else Nothing) validations

toggleInputValidationsOn : (String -> Bool) -> Bool -> Input -> Input
toggleInputValidationsOn pred b i = if pred i.name then {i | hideValidations = b} else i

--showInputValidationsOn = toggleInputValidationsOn True
--hideInputValidationsOn = toggleInputValidationsOn False
