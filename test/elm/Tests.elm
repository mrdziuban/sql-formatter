module Tests exposing (all)

import Test exposing (describe, Test)

import AppTest
import SQLFormatterTest

all: Test
all =
  describe "SQL Formatter"
    [ AppTest.all
    , SQLFormatterTest.all
    ]
