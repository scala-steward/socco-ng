let GithubActions =
      https://raw.githubusercontent.com/regadas/github-actions-dhall/master/package.dhall sha256:4c9474076eb57c92ea99ce3a4fdd9acc9bee1bdeedbc6f2b6840235128caf5b3

let matrix = toMap { scala = [ "2.12.11", "2.13.2", "2.13.3" ] }

let setup =
      [ GithubActions.steps.actions/checkout
      , GithubActions.steps.actions/cache
          { path =
              ''
              ~/.sbt
              "~/.cache/coursier"
              ''
          , key = "sbt"
          , hashFiles =
            [ "build.sbt"
            , "project/plugins.sbt"
            , "project/build.properties"
            , "project/Dependencies.scala"
            ]
          }
      , GithubActions.steps.actions/setup-java { java-version = "11" }
      ]

in  GithubActions.Workflow::{
    , name = "ci"
    , on = GithubActions.On::{
      , push = Some GithubActions.Push::{=}
      , pull_request = Some GithubActions.PullRequest::{=}
      }
    , jobs = toMap
        { build = GithubActions.Job::{
          , name = Some "build"
          , strategy = Some GithubActions.Strategy::{ matrix }
          , runs-on = GithubActions.types.RunsOn.ubuntu-latest
          , steps =
                setup
              # [ GithubActions.steps.run
                    { run = "sbt \"++\${{ matrix.scala}} compile\"" }
                ]
          }
        , publish = GithubActions.Job::{
          , name = Some "publish"
          , needs = Some [ "build" ]
          , runs-on = GithubActions.types.RunsOn.ubuntu-latest
          , `if` = Some "github.event_name == 'push'"
          , steps =
                setup
              # [ GithubActions.steps.olafurpg/setup-gpg
                , GithubActions.steps.olafurpg/sbt-ci-release
                ]
          }
        }
    }
