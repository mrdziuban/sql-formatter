package mrdziuban.sqlFormatter

import scala.language.implicitConversions
import scala.util.matching.Regex

object SQLFormatter {
  val sep = "~::~"

  case class T(str: String, shiftArr: List[String], tab: String, arr: List[String], parensLevel: Int, deep: Int)

  implicit class BooleanOps(b: Boolean) {
    def fold[A](ifTrue: A, ifFalse: A): A = Some(b).filter(identity).map(_ => ifTrue).getOrElse(ifFalse)
  }

  case class Pipe[A](a: A) { def |>[B](f: A => B) = f(a) }
  implicit def toPipe[A](a: A) = Pipe(a)

  def format(sql: String, numSpaces: Int): String = {
    val tab = " " * numSpaces
    val splitByQuotes =
      sql |>
        (s => "\\s+".r.replaceAllIn(s, " ")) |>
        (s => s.replaceAllLiterally("'", s"$sep'")) |>
        (s => s.split(sep).toList)
    val input = T(
      "",
      createShiftArr(tab),
      tab,
      splitByQuotes.zipWithIndex.flatMap(t => splitIfEven(t._2, t._1, tab)),
      0,
      0
    )

    val output = List.range(0, input.arr.length).foldLeft(input)((acc, i) => {
      val originalEl = acc.arr.lift(i).getOrElse("")
      val parensLevel = subqueryLevel(originalEl, acc.parensLevel);
      val arr = "SELECT|SET".r.findFirstIn(originalEl).isDefined.fold(
        acc.arr.patch(i, List(",\\s+".r.replaceAllIn(originalEl, s",\n${acc.tab * 2}")), 1),
        acc.arr)
      val el = arr.lift(i).getOrElse("")
      val (str, deep) = "\\(\\s*SELECT".r.findFirstIn(el).isDefined.fold(
        (s"${acc.str}${acc.shiftArr.lift(acc.deep + 1).getOrElse("")}${el}", acc.deep + 1),
        (
          el.contains("'").fold(s"${acc.str}${el}", s"${acc.str}${acc.shiftArr.lift(acc.deep).getOrElse("")}${el}"),
          (parensLevel < 1 && acc.deep != 0).fold(acc.deep - 1, acc.deep)
        ))

      acc.copy(str = str, arr = arr, parensLevel = parensLevel, deep = deep)
    })

    output.str |>
      (s => "\\s+\\n".r.replaceAllIn(s, "\n")) |>
      (s => "\\n+".r.replaceAllIn(s, "\n")) |>
      (s => s.trim)
  }

  private def createShiftArr(space: String): List[String] =
    List.range(0, 100).foldLeft(List[String]())((acc, i) => acc :+ s"\n${space * i}")

  private def subqueryLevel(str: String, level: Int): Int =
    level - (str.replaceAllLiterally("(", "").length - str.replaceAllLiterally(")", "").length)

  private def allReplacements(tab: String): List[(Regex, String)] =
    List(
      ("(?i) AND ".r,               s"${sep}${tab}AND "),
      ("(?i) BETWEEN ".r,           s"${sep}${tab}BETWEEN "),
      ("(?i) CASE ".r,              s"${sep}${tab}CASE "),
      ("(?i) ELSE ".r,              s"${sep}${tab}ELSE "),
      ("(?i) END ".r,               s"${sep}${tab}END "),
      ("(?i) FROM ".r,              s"${sep}FROM "),
      ("(?i) GROUP\\s+BY ".r,       s"${sep}GROUP BY "),
      ("(?i) HAVING ".r,            s"${sep}HAVING "),
      ("(?i) IN ".r,                " IN "),
      ("(?i) JOIN ".r,              s"${sep}JOIN "),
      (s"(?i) CROSS($sep)+JOIN ".r, s"${sep}CROSS JOIN "),
      (s"(?i) INNER($sep)+JOIN ".r, s"${sep}INNER JOIN "),
      (s"(?i) LEFT($sep)+JOIN ".r,  s"${sep}LEFT JOIN "),
      (s"(?i) RIGHT($sep)+JOIN ".r, s"${sep}RIGHT JOIN "),
      ("(?i) ON ".r,                s"${sep}${tab}ON "),
      ("(?i) OR ".r,                s"${sep}${tab}OR "),
      ("(?i) ORDER\\s+BY ".r,       s"${sep}ORDER BY "),
      ("(?i) OVER ".r,              s"${sep}${tab}OVER "),
      ("(?i)\\(\\s*SELECT ".r,      s"${sep}(SELECT "),
      ("(?i)\\)\\s*SELECT ".r,      s")${sep}SELECT "),
      ("(?i) THEN ".r,              s" THEN${sep}${tab}"),
      ("(?i) UNION ".r,             s"${sep}UNION${sep}"),
      ("(?i) USING ".r,             s"${sep}USING "),
      ("(?i) WHEN ".r,              s"${sep}${tab}WHEN "),
      ("(?i) WHERE ".r,             s"${sep}WHERE "),
      ("(?i) WITH ".r,              s"${sep}WITH "),
      ("(?i) SET ".r,               s"${sep}SET "),
      ("(?i) ALL ".r,               " ALL "),
      ("(?i) AS ".r,                " AS "),
      ("(?i) ASC ".r,               " ASC "),
      ("(?i) DESC ".r,              " DESC "),
      ("(?i) DISTINCT ".r,          " DISTINCT "),
      ("(?i) EXISTS ".r,            " EXISTS "),
      ("(?i) NOT ".r,               " NOT "),
      ("(?i) NULL ".r,              " NULL "),
      ("(?i) LIKE ".r,              " LIKE "),
      ("(?i)\\s*SELECT ".r,         "SELECT "),
      ("(?i)\\s*UPDATE ".r,         "UPDATE "),
      ("(?i)\\s*DELETE ".r,         "DELETE "),
      (s"(?i)($sep)+".r,            sep)
    )

  private def splitSql(str: String, tab: String): List[String] =
    allReplacements(tab).foldLeft("\\s+".r.replaceAllIn(str, " "))(
      (acc, r) => r._1.replaceAllIn(acc, r._2)).split(sep).toList

  private def splitIfEven(i: Int, str: String, tab: String): List[String] =
    (i % 2 == 0).fold(splitSql(str, tab), List(str))
}
