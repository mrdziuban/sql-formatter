import sbt._
import Keys._

scalacOptions ++= Seq(
  "-deprecation",
  "-encoding", "UTF-8", // yes, this is 2 args
  "-feature",
  "-unchecked",
  "-Xfatal-warnings",
  "-Xlint",
  "-Yno-adapted-args",
  "-Ywarn-dead-code", // N.B. doesn't work well with the ??? hole
  "-Ywarn-infer-any",
  "-Ywarn-numeric-widen",
  "-Ywarn-unused",
  "-Ywarn-value-discard",
  "-Xfuture",
  "-Ydelambdafy:method",
  "-target:jvm-1.8"
)

lazy val sqlFormatter = Project(
  "sql-formatter",
  file("."),
  settings = Seq(
    organization := "mrdziuban",
    name := "sql-formatter",
    version := "1.0",
    scalaVersion := "2.12.1",
    scalaSource in Compile := baseDirectory.value / "scalajs" / "src",
    scalaSource in Test := baseDirectory.value / "test" / "scalajs",
    libraryDependencies ++= Seq(
      "org.scala-js" %%% "scalajs-dom" % "0.9.1",
      "org.scalatest" %%% "scalatest" % "3.0.1" % "test"
    )
  )
).enablePlugins(ScalaJSPlugin)
