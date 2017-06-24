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
  "-Ywarn-unused:-params,_",
  "-Ywarn-unused-import",
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
    scalaVersion := "2.12.2",
    scalaSource in Compile := baseDirectory.value / "scalajs" / "src",
    scalaSource in Test := baseDirectory.value / "test" / "scalajs",
    scalaJSUseMainModuleInitializer := true,
    libraryDependencies ++= Seq(
      "org.scala-js" %%% "scalajs-dom" % "0.9.2",
      "org.scalatest" %%% "scalatest" % "3.0.3" % "test"
    )
  )
).enablePlugins(ScalaJSPlugin)
