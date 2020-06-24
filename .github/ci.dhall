let GithubActions =
      https://raw.githubusercontent.com/regadas/github-actions-dhall/master/package.dhall sha256:37feb22e3fd5f7b6e0c94d1aaa94bf704422792fb898dbbcc5d1dabe9f9b3fbf

let matrix = toMap { scala = [ "2.12.11", "2.13.2" ] }

let setup =
      [ GithubActions.steps.checkout
      , GithubActions.steps.run
          { run =
              ''
              shasum build.sbt \
                project/plugins.sbt \
                project/build.properties > gha.cache.tmp
              ''
          }
      , GithubActions.steps.cache
          { path = "~/.sbt", key = "sbt", hashFile = "gha.cache.tmp" }
      , GithubActions.steps.cache
          { path = "~/.cache/coursier"
          , key = "coursier"
          , hashFile = "gha.cache.tmp"
          }
      , GithubActions.steps.olafurpg/java-setup { java-version = "11" }
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
          , if = Some "github.event_name == 'push'"
          , steps =
                setup
              # [ GithubActions.steps.olafurpg/gpg-setup
                , GithubActions.steps.olafurpg/sbt-ci-release
                ]
          }
        }
    }
