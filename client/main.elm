import Http
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as JsonD
import Json.Decode exposing (Decoder)

import Form exposing (..)

main = formMainProgram inputs "http://localhost:5000/signup" validations

inputs = 
    [ textInputWithTrigger OnInputChange "user_name" "Username: " "Enter your username" Mass
    , emailInput "user_mail" "Email: " "example@gmail.com" Mass
    , passwordInput "user_passwd" "Password: " Queued 
    , passwordInput "user_passwd" "Password confirm: " Queued 
    ]

validations : List (String, Validation)
validations = 
    [ ("user_name", withPredicate (not << String.isEmpty) "User name can't be empty" )
    , ("user_mail", withPredicate (String.contains "@") "Doesn't seem like a valid email")
    , ("user_passwd", withPredicate (minLength 6) "Passwords must be at least 6 characters long")
    , ("user_name", withPredicate (minLength 3) "User name is too short")
    , ("user_name", withPredicate (not << String.contains " ") "User name cant contain spaces")
    ]

minLength : Int -> String -> Bool
minLength n s = String.length s >= n
