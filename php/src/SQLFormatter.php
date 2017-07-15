<?php

class SQLFormatter {
  public $sep = '~::~';

  public function format($sql, $numSpaces) {
    $tab = str_repeat(' ', $numSpaces);
    $splitByQuotes = explode($this->sep, preg_replace('/\s+/', ' ', preg_replace("/'/", $this->sep . "'", $sql)));
    $input = array(
      'str' => '',
      'shiftArr' => $this->createShiftArr($tab),
      'tab' => $tab,
      'parensLevel' => 0,
      'deep' => 0
    );

    $inArr = $this->genArray($splitByQuotes, $tab);
    $outArr = array();
    $acc = $input;
    foreach($inArr as $i => $originalEl) {
      $parensLevel = $this->subqueryLevel($originalEl, $acc['parensLevel']);
      $el = preg_match('/SELECT|SET/', $originalEl) ? preg_replace('/,\s+/', ",\n" . $acc['tab'] . $acc['tab'], $originalEl) : $originalEl;
      $out = $this->updateOutput($el, $parensLevel, $acc);

      $outArr[$i] = $el;
      $acc['str'] = $out[0];
      $acc['parensLevel'] = $parensLevel;
      $acc['deep'] = $out[1];
    }

    return trim(preg_replace('/\s+\\n/', "\n", preg_replace('/\\n+/', "\n", $acc['str'])));
  }

  private function updateOutput($el, $parensLevel, $acc) {
    if (preg_match('/\(\s*SELECT/', $el)) {
      return array(($acc['str'] . $acc['shiftArr'][$acc['deep'] + 1] . $el), $acc['deep'] + 1);
    } else {
      return array(
        (preg_match("/'/", $el) ? ($acc['str'] . $el) : ($acc['str'] . $acc['shiftArr'][$acc['deep']] . $el)),
        ($parensLevel < 1 && $acc['deep'] !== 0 ? $acc['deep'] - 1 : $acc['deep'])
      );
    }
  }

  private function createShiftArr($tab) {
    $arr = array();
    for ($i = 0; $i < 100; $i++) {
      array_push($arr, "\n" . str_repeat($tab, $i));
    }
    return $arr;
  }

  private function genArray($splitByQuotes, $tab) {
    $arr = array();
    foreach($splitByQuotes as $i => $a) {
      foreach($this->splitIfEven($i, $splitByQuotes[$i], $tab) as $el) {
        $arr[] = $el;
      }
    }
    return $arr;
  }

  private function subqueryLevel($str, $level) {
    return $level - (strlen(preg_replace('/\(/', '', $str)) - strlen(preg_replace('/\)/', '', $str)));
  }

  private function allReplacements($tab) {
    $sep = $this->sep;
    return array(
      function($str) use($tab, $sep) { return preg_replace('/ AND /i',              $sep . $tab . 'AND ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ BETWEEN /i',          $sep . $tab . 'BETWEEN ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ CASE /i',             $sep . $tab . 'CASE ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ ELSE /i',             $sep . $tab . 'ELSE ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ END /i',              $sep . $tab . 'END ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ FROM /i',             $sep . 'FROM ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ GROUP\s+BY /i',       $sep . 'GROUP BY ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ HAVING /i',           $sep . 'HAVING ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ IN /i',               ' IN ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ JOIN /i',             $sep . 'JOIN ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ CROSS(~::~)+JOIN /i', $sep . 'CROSS JOIN ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ INNER(~::~)+JOIN /i', $sep . 'INNER JOIN ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ LEFT(~::~)+JOIN /i',  $sep . 'LEFT JOIN ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ RIGHT(~::~)+JOIN /i', $sep . 'RIGHT JOIN ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ ON /i',               $sep . $tab . 'ON ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ OR /i',               $sep . $tab . 'OR ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ ORDER\s+BY /i',       $sep . 'ORDER BY ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ OVER /i',             $sep . $tab . 'OVER ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/\(\s*SELECT /i',       $sep . '(SELECT ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/\)\s*SELECT /i',       ')' . $sep . 'SELECT ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ THEN /i',             ' THEN' . $sep . $tab, $str); },
      function($str) use($tab, $sep) { return preg_replace('/ UNION /i',            $sep . 'UNION' . $sep, $str); },
      function($str) use($tab, $sep) { return preg_replace('/ USING /i',            $sep . 'USING ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ WHEN /i',             $sep . $tab . 'WHEN ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ WHERE /i',            $sep . 'WHERE ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ WITH /i',             $sep . 'WITH ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ SET /i',              $sep . 'SET ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ ALL /i',              ' ALL ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ AS /i',               ' AS ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ ASC /i',              ' ASC ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ DESC /i',             ' DESC ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ DISTINCT /i',         ' DISTINCT ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ EXISTS /i',           ' EXISTS ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ NOT /i',              ' NOT ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ NULL /i',             ' NULL ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/ LIKE /i',             ' LIKE ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/\s*SELECT /i',         'SELECT ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/\s*UPDATE /i',         'UPDATE ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/\s*DELETE /i',         'DELETE ', $str); },
      function($str) use($tab, $sep) { return preg_replace('/(~::~)+/', $sep, $str); }
    );
  }

  private function splitSql($str, $tab) {
    $str = preg_replace('/\s+/', ' ', $str);
    $replacements = $this->allReplacements($tab);
    foreach($replacements as $replacementFn) {
      $str = $replacementFn($str);
    }
    return explode($this->sep, $str);
  }

  private function splitIfEven($i, $str, $tab) {
    return ($i % 2) === 0 ? $this->splitSql($str, $tab) : array($str);
  }
}

if ($_ENV['EXPORTS'] !== 'false') {
  $module->exports = new SQLFormatter;
}
